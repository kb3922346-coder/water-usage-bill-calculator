WATER USAGE & BILL CALCULATOR — C BACKEND VERSION

Technologies:
- HTML: webpage structure
- CSS: webpage design
- JavaScript: sends readings to the backend and displays the result
- C: validates meter readings and calculates the bill

-----------------------------------------------------------
OPTION 1: QUICK RUN (RECOMMENDED — NO XAMPP NEEDED)
-----------------------------------------------------------
A portable launcher and CGI server is included.
1. Simply double-click `run.bat`.
   - It will automatically compile calculate.c using your installed CodeBlocks MinGW GCC.
   - It will start the local server and automatically open:
     http://localhost:8080/

-----------------------------------------------------------
OPTION 2: RUN ON WINDOWS USING XAMPP (Apache)
-----------------------------------------------------------
1. Install XAMPP with Apache.
2. Copy this project folder into:
   C:\xampp\htdocs\WaterUsage
3. Open Command Prompt and compile calculate.c:
   gcc calculate.c -o calculate.cgi
4. Copy calculate.cgi into:
   C:\xampp\cgi-bin\calculate.cgi
   (or into C:\xampp\htdocs\WaterUsage\cgi-bin\calculate.cgi if configured)
5. Start Apache from the XAMPP Control Panel.
6. Open in your browser:
   http://localhost/WaterUsage/

SAMPLE TARIFF IN calculate.c:
- First 10 units: Rs. 5 per unit
- Next 10 units: Rs. 8 per unit
- Above 20 units: Rs. 10 per unit
Change calculate_bill() in calculate.c to match custom tariffs.

PROJECT FLOW:
HTML form -> JavaScript fetch -> C CGI backend -> JSON response -> Result display.

FILES:
- index.html        : Frontend UI
- style.css         : Stylesheet
- script.js         : Frontend interaction & fetch handler
- calculate.c       : Backend C calculation logic
- server.ps1        : Built-in local HTTP + CGI server
- run.bat           : 1-click launcher
- cgi-bin/          : Directory containing compiled calculate.exe & calculate.cgi
