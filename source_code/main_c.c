#include <stdio.h>
// RTC Addresses
#define S1 0x00
#define S10 0x01
#define MI1 0x02
#define MI10 0x03
#define H1 0x04
#define H10 0x05
#define D1 0x06
#define D10 0x07
#define MO1 0x08
#define MO10 0x09
#define Y1 0x0A
#define Y10 0x0B
#define W 0x0C
#define CD 0x0D
#define CE 0x0E
#define CF 0x0F
// External Hardware addresses
__xdata unsigned char * __code LCD_BUSY = 0x2002;
__xdata unsigned char * __code LCD_CMD = 0X2000;
__xdata unsigned char * __code LCD_DATA = 0x2001;
__xdata unsigned char * __code LCD_COLOR = 0x4000;
__xdata unsigned char * __code SEG_DISPLAY = 0x0000;
__xdata unsigned char * __code ADC = 0x6000;
__xdata unsigned char * __code RTC = 0x8000;
// Constant stuff
__code unsigned char LCD_LINES[] = {0x00, 0x40, 0x14, 0x54};
__code unsigned char KEYPAD_CHARS[] = {'1', '4', '7', 'F',
                                        '2', '5', '8', '0',
                                        '3', '6', '9', 'E',
                                        'A', 'B', 'C', 'D', 'X' }; // X should not be accessable
// IO/M Bit
__sbit __at (0xB5) IO_M;
__sfr __at (0x90) P1;
// Global variables
unsigned int __xdata KEYPAD_STATE;
int __xdata whole_temp;
int __xdata frac_temp;
__sfr __at (0xE0) ACC; 
__sfr __at (0xF0) BREG;
// Prototypes
void delay1ms();
void init_LCD();
void clear_LCD();
void set_LCD_line(char line);
void init_RTC();
void while_rtc_busy();
char read_rtc(char reg);
void putchar(char c);
char getchar();
char getchar_nb();
void change_display(char c);
void scan_keypad();
char ram_test();
void do_conversion(int * whole, int * frac);


int main(void) {
    init_LCD(); // Init hardware
    init_RTC();
    *LCD_COLOR = 0x02;
    BREG = ram_test(); 
    clear_LCD();
    if(BREG != 0) {
        set_LCD_line(1);
        printf_tiny("  RAM TEST FAILED  ");
        while(1);
    }
    while(1) {
        scan_keypad();
        scan_keypad();
        do_conversion(&whole_temp, &frac_temp);
        set_LCD_line(0);
        printf_tiny("%d%d", read_rtc(H10), read_rtc(H1));
        printf_tiny(":%d%d:", read_rtc(MI10), read_rtc(MI1));
        printf_tiny("%d%d", read_rtc(S10), read_rtc(S1));
        set_LCD_line(1);
        printf_tiny("%d.%d", whole_temp, frac_temp);
        set_LCD_line(2);
        printf_tiny("%x", KEYPAD_STATE);
        set_LCD_line(3);
        putchar(getchar_nb());
    }
}

void delay1ms() {
    unsigned char x = 50;
    unsigned char y = 255;
    while(x > 0){
        x--;
        y = 255;
        while(y > 0) {
            y--;
        }
    }
    return;
}
/* putchar
 * Function that writes a character to the LCD
 * c character to write
 */
void putchar(char c) {
    IO_M = 1;
    while(*LCD_BUSY & 0x80); // Waits until the LCD is not busy
    *LCD_DATA = c;
    IO_M = 0;
    return;
}
char getchar() {
    KEYPAD_STATE = 0xFFFF;
    while(KEYPAD_STATE == 0xFFFF) {
        scan_keypad();
        scan_keypad();
        scan_keypad(); // Allow for bouncing
    }
    BREG = 0;
    while(1) {
        if((KEYPAD_STATE & 0x0001) == 0) {
            return *(KEYPAD_CHARS + BREG);
        }
        KEYPAD_STATE = KEYPAD_STATE >> 1; // Shift and scan next key; 
    }
}
char getchar_nb() {
    BREG = 0;
    scan_keypad();
    scan_keypad();
    scan_keypad(); // Allow for bouncing
    while(1) {
        if((KEYPAD_STATE & 0x0001) == 0) {
            return *(KEYPAD_CHARS + BREG);
        }
        KEYPAD_STATE = KEYPAD_STATE >> 1;
        BREG++;
    }
}
void clear_LCD() {
    IO_M = 1;
    while(*LCD_BUSY & 0x80);
    *LCD_CMD = 0x01;
    IO_M = 0;
    return;
}
void init_LCD() {
    IO_M = 1;
    *LCD_CMD = 0b00111100;   // Function Set
    delay1ms();
    *LCD_CMD = 0b00111100;   // Function set
    delay1ms();
    *LCD_CMD = 0b00001100;   // Display On
    delay1ms();
    *LCD_CMD = 0b00000001;   // Clear Display
    delay1ms();
    *LCD_CMD = 0b00000110;   // Entry Mode set
    delay1ms();
    *LCD_CMD = 0b01000000;   // Set CG Ram
    delay1ms();
    *LCD_CMD = 0b10000000;   // Set DD Ram
    delay1ms();
    *LCD_CMD = 0b00000010;   // Set cursor home
    delay1ms();
    IO_M = 0;
    return;
}
void set_LCD_line(char line) {
    IO_M = 1;
    while(*LCD_BUSY & 0x80);
    *LCD_CMD = 0x80 | (*(LCD_LINES + line));
    IO_M = 0;
    return;
}
/* change_display()
 *  Function that writes to the 7seg
 *  c: byte to write
 */
void change_display(char c){
    IO_M = 1;
    *SEG_DISPLAY = c;
    IO_M = 0;
    return;
}
void init_RTC() {
    // Procedure for init_RTC
    unsigned char i = 0;
    IO_M = 1;   // Set to IO mode
    *(RTC + CF) = 0x04; 
    *(RTC + CD) = 0x04;
    while_rtc_busy();
    *(RTC + CF) = 0x07; // Stop timer
    while(i < 0x0D) {
        *(RTC + i) = 0x00; // Load regs with 0s
        i++;
    }
    *(RTC + CF) = 0x04; // Start timer

}
char read_rtc(char reg) {
    IO_M = 1;
    while_rtc_busy();
    return (*(RTC + reg) & 0x0F);
}
void while_rtc_busy() {
    IO_M = 1;
    do {
    *(RTC + CD) = 0X00;
    *(RTC + CD) = 0X01;
    } while(*(RTC + CD) & 0x02);
    *(RTC + CD) = 0x00;
    return;
}
void scan_keypad(){
    char i = 0;
    KEYPAD_STATE = 0;
    // Column 1
    P1 = 0XFE;
    KEYPAD_STATE |= (((P1 & 0xF0) >> 4));
    // Column 2
    P1 = 0xFD;
    KEYPAD_STATE |= (((P1 & 0xF0) >> 4) << 4);
    // Column 3
    P1 = 0xFB;
    KEYPAD_STATE |= (((P1 & 0xF0) >> 4) << 8);
    // Column 4
    P1 = 0xF7;
    KEYPAD_STATE |= (((P1 & 0xF0) >> 4) << 12);
    return;
}
void do_conversion(int * whole, int * frac) {
    unsigned int temp = 0;
    IO_M = 1; // Set IO mode
    *ADC = 0x00; // Start conversion
    delay1ms(); // Wait for conversion
    BREG = *ADC;
    IO_M = 0;   // Done with IO mode
    temp = BREG * (195.3);
    *whole = temp / 100;
    *frac = temp % 100;
    return;

}
char ram_test() {
    __xdata unsigned char *i = 0x0000;
    IO_M = 0;
    set_LCD_line(1);
    printf_tiny("    TESTING RAM!   ");
    set_LCD_line(2);
    // Check with 55
    BREG = 0x55;
    do{
        *i = BREG;
        i++;
    }while(i > 0x0000);
    printf_tiny("    ===");
    do {
        BREG = *i;
        if(BREG != 0x55) {
            return 0xFF;
        }
        i++;
    } while(i > 0x0000);
    printf_tiny("===");
    // Check with AA
    BREG = 0xAA;
    do{
        *i = BREG;
        i++;
    }while(i > 0x0000);
    printf_tiny("===");
    do {
        BREG = *i;
        if(BREG != 0xAA) {
            return 0xFF;
        }
        i++;
    } while(i > 0x0000);
    printf_tiny("===");
    return 0;
}
/* memory_dump
 * Dumps a specified number of bytes starting at start from external memory
 * start: address to start dump from
 * num_bytes: number of bytes to dump ( < 4) 
 */
void memory_dump(unsigned char * start, unsigned char num_bytes) {
    printf_tiny("%d ", start);
    BREG = 0; // work register
    
}