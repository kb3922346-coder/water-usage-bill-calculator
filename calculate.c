#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>

#if defined(_WIN32)
#include <fcntl.h>
#include <io.h>
#endif

/* Read a URL-encoded form value such as previous=120&current=145 safely */
void get_value(const char *data, const char *key, char *output, size_t output_size) {
    char pattern[40];
    const char *start;
    size_t i = 0;

    if (output == NULL || output_size == 0) return;
    output[0] = '\0';

    if (data == NULL || key == NULL) return;

    snprintf(pattern, sizeof(pattern), "%s=", key);
    start = data;

    while ((start = strstr(start, pattern)) != NULL) {
        if (start == data || *(start - 1) == '&') {
            start += strlen(pattern);
            break;
        }
        start++;
    }

    if (start == NULL) return;

    while (*start != '\0' && *start != '&' && i < output_size - 1) {
        if (*start == '+') {
            output[i++] = ' ';
        } else if (*start == '%' && isxdigit((unsigned char)start[1]) &&
                   isxdigit((unsigned char)start[2])) {
            char hex[3] = { start[1], start[2], '\0' };
            output[i++] = (char)strtol(hex, NULL, 16);
            start += 2;
        } else {
            output[i++] = *start;
        }
        start++;
    }

    output[i] = '\0';
}

/* Sample tariff: first 10 units at Rs. 5, next 10 at Rs. 8,
   and all units above 20 at Rs. 10. */
double calculate_bill(double units) {
    if (units <= 10.0) {
        return units * 5.0;
    } else if (units <= 20.0) {
        return (10.0 * 5.0) + ((units - 10.0) * 8.0);
    } else {
        return (10.0 * 5.0) + (10.0 * 8.0) + ((units - 20.0) * 10.0);
    }
}

int main(void) {
#if defined(_WIN32)
    _setmode(_fileno(stdin), _O_BINARY);
    _setmode(_fileno(stdout), _O_BINARY);
#endif

    char *length_text = getenv("CONTENT_LENGTH");
    int content_length = length_text ? atoi(length_text) : 0;
    char *form_data;
    char previous_text[64];
    char current_text[64];
    char *end_ptr;
    double previous, current, units, bill;

    printf("Content-Type: application/json\r\n\r\n");

    if (content_length <= 0 || content_length > 10000) {
        printf("{\"error\":\"Missing or invalid form data.\"}");
        return 0;
    }

    form_data = (char *)malloc((size_t)content_length + 1);
    if (form_data == NULL) {
        printf("{\"error\":\"Server memory error.\"}");
        return 0;
    }

    if (fread(form_data, 1, (size_t)content_length, stdin) != (size_t)content_length) {
        printf("{\"error\":\"Could not read form data.\"}");
        free(form_data);
        return 0;
    }
    form_data[content_length] = '\0';

    get_value(form_data, "previous", previous_text, sizeof(previous_text));
    get_value(form_data, "current", current_text, sizeof(current_text));

    if (previous_text[0] == '\0' || current_text[0] == '\0') {
        printf("{\"error\":\"Both meter readings are required.\"}");
        free(form_data);
        return 0;
    }

    previous = strtod(previous_text, &end_ptr);
    if (*end_ptr != '\0' || !isfinite(previous) || previous < 0) {
        printf("{\"error\":\"Previous reading must be a valid non-negative number.\"}");
        free(form_data);
        return 0;
    }

    current = strtod(current_text, &end_ptr);
    if (*end_ptr != '\0' || !isfinite(current) || current < 0) {
        printf("{\"error\":\"Current reading must be a valid non-negative number.\"}");
        free(form_data);
        return 0;
    }

    if (current < previous) {
        printf("{\"error\":\"Current reading cannot be less than previous reading.\"}");
        free(form_data);
        return 0;
    }

    units = current - previous;
    bill = calculate_bill(units);

    printf("{\"previous\":%.2f,\"current\":%.2f,\"units\":%.2f,\"bill\":%.2f}",
           previous, current, units, bill);

    free(form_data);
    return 0;
}
