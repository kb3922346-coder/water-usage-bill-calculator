const billForm = document.getElementById("billForm");
const resetBtn = document.getElementById("resetBtn");
const calculateBtn = document.getElementById("calculateBtn");
const result = document.getElementById("result");
const error = document.getElementById("error");

billForm.addEventListener("submit", async function (event) {
  event.preventDefault();

  const previous = document.getElementById("previous").value;
  const current = document.getElementById("current").value;

  error.textContent = "";
  result.hidden = true;

  if (previous === "" || current === "" ||
      Number(previous) < 0 || Number(current) < 0) {
    error.textContent = "Please enter valid, non-negative meter readings.";
    return;
  }

  if (Number(current) < Number(previous)) {
    error.textContent = "Current reading cannot be less than previous reading.";
    return;
  }

  calculateBtn.disabled = true;
  calculateBtn.textContent = "Calculating...";

  try {
    // The calculation is performed by the C CGI backend.
    const response = await fetch("cgi-bin/calculate.cgi", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ previous, current })
    });

    const rawText = await response.text();
    let data;
    try {
      const jsonStart = rawText.indexOf("{");
      const jsonEnd = rawText.lastIndexOf("}");
      if (jsonStart !== -1 && jsonEnd !== -1) {
        data = JSON.parse(rawText.substring(jsonStart, jsonEnd + 1));
      } else {
        data = JSON.parse(rawText);
      }
    } catch (parseErr) {
      throw new Error("Invalid response format received from backend: " + rawText.substring(0, 80));
    }

    if (data.error) {
      error.textContent = data.error;
      return;
    }

    document.getElementById("oldValue").textContent = Number(data.previous).toFixed(2);
    document.getElementById("newValue").textContent = Number(data.current).toFixed(2);
    document.getElementById("unitsValue").textContent = Number(data.units).toFixed(2) + " units";
    document.getElementById("billValue").textContent =
      "₹" + Number(data.bill).toFixed(2);

    result.hidden = false;
  } catch (err) {
    error.textContent = "Backend connection error: " + err.message +
      " Please make sure the backend server is running.";
  } finally {
    calculateBtn.disabled = false;
    calculateBtn.textContent = "Calculate my bill";
  }
});

resetBtn.addEventListener("click", function () {
  billForm.reset();
  result.hidden = true;
  error.textContent = "";
});
