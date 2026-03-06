// ============================================================
// smoke_test.c
// Tests: CPU core, UART, GPIO
// ============================================================

// ---------- Memory-mapped register addresses ----------

// UART (base 0x00018000)
#define UART_DIV    (*(volatile unsigned int *)0x00018000)  // baud rate divisor
#define UART_DAT    (*(volatile unsigned int *)0x00018004)  // TX/RX data
#define UART_STATUS (*(volatile unsigned int *)0x00018008)  // status (bit0 = TX busy)

// GPIO (base 0x00020000)
#define GPIO_DATA   (*(volatile unsigned int *)0x00020000)  // pin values
#define GPIO_DIR    (*(volatile unsigned int *)0x00020004)  // direction (1=output, 0=input)

// ---------- UART helpers ----------

void uart_set_baud(unsigned int divisor) {
    UART_DIV = divisor;
}

void uart_putc(char c) {
    while (UART_STATUS & 1);  // wait while TX busy
    UART_DAT = c;
}

void uart_puts(const char *s) {
    while (*s) {
        uart_putc(*s);
        s++;
    }
}

// ---------- GPIO helpers ----------

void gpio_set_output(unsigned int pin_mask) {
    GPIO_DIR = pin_mask;  // set pins as outputs
}

void gpio_write(unsigned int value) {
    GPIO_DATA = value;    // write to output pins
}

unsigned int gpio_read() {
    return GPIO_DATA;     // read pin state
}

// ---------- CPU test ----------
// Simple arithmetic to confirm the core is running correctly

int cpu_add(int a, int b) { return a + b; }
int cpu_mul(int a, int b) { return a * b; }

// ---------- main ----------

int main() {
    // --- CPU test ---
    int sum = cpu_add(10, 20);   // expected: 30
    int product = cpu_mul(6, 7); // expected: 42

    // --- UART test ---
    // divisor = clk_freq / baud_rate
    // example: 50MHz / 115200 = 434
    uart_set_baud(434);

    uart_puts("Tetrel SoC smoke test\n");

    if (sum == 30) {
        uart_puts("CPU ADD: PASS\n");
    } else {
        uart_puts("CPU ADD: FAIL\n");
    }

    if (product == 42) {
        uart_puts("CPU MUL: PASS\n");
    } else {
        uart_puts("CPU MUL: FAIL\n");
    }

    // --- GPIO test ---
    // set all 32 pins as outputs
    gpio_set_output(0xFFFFFFFF);

    // write a pattern
    gpio_write(0xAAAAAAAA);

    // read it back
    unsigned int readback = gpio_read();

    if (readback == 0xAAAAAAAA) {
        uart_puts("GPIO: PASS\n");
    } else {
        uart_puts("GPIO: FAIL\n");
    }

    uart_puts("Smoke test done.\n");

    // hang forever
    while (1);

    return 0;
}