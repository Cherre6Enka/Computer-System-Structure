# Computer System Structure 🖥️

This repository contains academic projects focused on digital logic design and low-level hardware programming.

## 🌐 Interactive Logic Simulator
A full-scale digital logic simulation developed in **CircuitVerse**.
👉 **[Launch Live Simulator](https://YOUR_USERNAME.github.io/Computer-System-Structure/)**

* **Concepts:** Combinational logic, Adders, and Multiplexers.
* **Platform:** CircuitVerse (Embedded via GitHub Pages).

---

## 🔬 Low-Level Hardware Programming (MCS-51)
Implementation of a 4-digit multiplexed counter for the **STC89C52RC** microcontroller using 8051 Assembly.

### Features:
* **Timer0 Interrupts:** Handles high-frequency display multiplexing.
* **Dynamic Scanning:** Controls a 4-digit 7-segment display via `P0` (segments) and `P1` (digit enable).
* **Input Logic:** Individual digit increment (0-9) via push-buttons on `P3.2–P3.5`.
* **Debounce Logic:** Software-based signal stabilization for reliable button presses.

### Hardware Mapping:
| Component | Port | Description |
|-----------|------|-------------|
| Segments  | P0.0-P0.7 | Segment lines (a-g + dp) |
| Digits    | P1.3-P1.6 | Digit enable (active-LOW) |
| Buttons   | P3.2-P3.5 | Increment triggers |

---

## 📂 Repository Structure
* `index.html` — Full-screen simulator integration.
* `main.asm` — Assembly source code for the STC89C52RC chip.
* `README.md` — Project documentation.

---
*Developed as part of the Computer System Structure course at TSI.*
