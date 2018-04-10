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
__code unsigned char KEYPAD_CHARS[] = { '1', '4', '7', 'F',
                                        '2', '5', '8', '0',
                                        '3', '6', '9', 'E',
                                        'A', 'B', 'C', 'D', 'X' }; // X should not be accessable
__code unsigned char KEYPAD_HEX[] = {   0x01, 0x04, 0x07, 0x0F,
                                        0x02, 0x05, 0x08, 0x00,
                                        0x03, 0x06, 0x09, 0x0E,
                                        0x0A, 0x0B, 0x0C, 0x0D, 0xFF}; // 0xFF should not be accessable
__code unsigned char HOME[] = {0x00, 0x04, 0x0A, 0x11, 0x0E, 0x0E, 0x00}; // Home Icon
// Special function register locations
__sbit __at (0xB5) IO_M;
__sbit __at (0xD5) F0; // Personal flag
__sfr __at (0x90) P1;
// Global variables
unsigned int __xdata KEYPAD_STATE; // State of keypad since last scan
int __xdata whole_temp; // whole part of temperature
int __xdata frac_temp; // Fraction part of temperature
char __xdata last_key; // Last Keypad index since last scan
int  (* __data  state)(void);
/* current state of program
 * 0x00 = Main menu, 0x01 = Dump program, 0x02 = Move program 
 * 0x03 = Edit program, 0x04 = Search program, 0x05 = Debug mode,
 * 0x06 = Oregon Trail*? 
 */
__xdata char * __idata dump_index;
__sfr __at (0xE0) ACC; 
__sfr __at (0xF0) BREG;
// Prototypes
// Delays
void delay1ms();
void delay(int x);
// LCD interfacing functions
void init_LCD();
void clear_LCD();
void set_LCD_line(char line);
void set_LCD_cursor(char loc);
void putchar(char c);
void set_CG_char(char c, __code char * map);
// Keypad interfacing functions
char getchar_nb();
char getchar_b();
void scan_keypad();
// RTC interfacing functions
void init_RTC();
void while_rtc_busy();
char read_rtc(char reg);
// 7Seg functions...
void change_display(char c);
// ADC interfacing functions
void do_conversion(int * whole, int * frac);
// Memory Functions
char ram_test();
void memory_dump_line( __xdata char * start, unsigned char num_bytes, char line);
void move_memory(__xdata char * src, __xdata char * dest, unsigned char num_bytes);
void edit_memory(__xdata char * dest, char val);
int search_memory(__xdata char * start, char val, unsigned char num_bytes);
// Programs
int dump_program();


int main(void) {
    char temp = 0x00;
    init_LCD(); // Init hardware
    init_RTC();
    *LCD_COLOR = 0x05; // Set green screen
    // Test Ram
    BREG = ram_test(); 
    clear_LCD();
    if(BREG != 0) {
        set_LCD_line(1);
        printf_tiny("  RAM TEST FAILED  ");
        while(1);
    }
    set_CG_char(0, HOME);
    dump_index = 0;
    state = dump_program;
    while(1) {
        // do_conversion(&whole_temp, &frac_temp);
        // set_LCD_line(0);
        // printf_tiny("%d%d", read_rtc(H10), read_rtc(H1));
        // printf_tiny(":%d%d:", read_rtc(MI10), read_rtc(MI1));
        // printf_tiny("%d%d", read_rtc(S10), read_rtc(S1));
        // set_LCD_line(1);
        // printf_tiny("%d.%d", whole_temp, frac_temp);
        // set_LCD_line(2);
        // temp = getchar_nb();
        // putchar(*(temp + KEYPAD_CHARS));
        // memory_dump_line(dump_index, 4, 3);
        // dump_index = dump_index + 4;
        // delay(100);
        state = state();
    }
}
int dump_program() {
    // local vars
    __xdata char * start = 0;
    __idata index = 0;
    clear_LCD();
    set_LCD_line(0);
    printf_tiny("Enter Address: ");
    getchar_b();
    start = (__xdata char *)(*(last_key + KEYPAD_HEX) << 12);
    putchar(*(last_key + KEYPAD_CHARS));
    getchar_b();
    start += (*(last_key + KEYPAD_HEX) << 8);
    putchar(*(last_key + KEYPAD_CHARS));
    getchar_b();
    start += (*(last_key + KEYPAD_HEX) << 4);
    putchar(*(last_key + KEYPAD_CHARS));
    getchar_b();
    start += *(last_key + KEYPAD_HEX);
    putchar(*(last_key + KEYPAD_CHARS));
    set_LCD_line(0);
    printf_tiny("Prev(0) Next(1) ");
    putchar(0x00);
    printf_tiny("(2)"); 
    do {
        memory_dump_line(start, 4, 1);
        start += 4;
        memory_dump_line(start, 4, 2);
        start += 4;
        memory_dump_line(start, 4, 3);
        start += 4;
        do {
            getchar_b();
        } while(last_key > 2);
        if(*(last_key + KEYPAD_HEX) == 0x00) {
            start -= 24; // 2 * 3 * 4 = 24 
        } else if(*(last_key + KEYPAD_HEX) == 0x01) {
            // do nothing
        } else if(*(last_key + KEYPAD_HEX) == 0x02) {
            return dump_program;
        }
    } while(1);
}
void delay1ms() {
    unsigned char x = 10;
    unsigned char y = 128;
    while(x > 0){
        x--;
        y = 128;
        while(y > 0) {
            y--;
        }
    }
    return;
}
void delay(int x) {
    for(x; x > 0; x--) {
        delay1ms();
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
char getchar_b() {
    KEYPAD_STATE = 0x0000;
    while(KEYPAD_STATE != 0xFFFF) { // Wait for blank state
        scan_keypad();
        scan_keypad();
        scan_keypad(); // Allow for bouncing
    }
    KEYPAD_STATE = 0xFFFF;
    while(KEYPAD_STATE == 0xFFFF) { // now record next keypress
        scan_keypad();
        scan_keypad();
        scan_keypad(); // Allow for bouncing
    }
    BREG = 0;
    while(1) {
        if((KEYPAD_STATE & 0x0001) == 0) {
            last_key = BREG;
            return last_key;
        }
        KEYPAD_STATE = KEYPAD_STATE >> 1; // Shift and scan next key; 
        BREG++;
    }
}
char getchar_nb() {
    scan_keypad();
    scan_keypad();
    scan_keypad(); // Allow for bouncing
    BREG = 0;    
    while(1) {
        if((KEYPAD_STATE & 0x0001) == 0) {
            last_key = BREG;
            return last_key;
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
void set_LCD_cursor(char loc) {
    IO_M = 1;
    while(*LCD_BUSY & 0x80);
    *LCD_CMD = 0x80 | (loc);
    IO_M = 0;
    return;
}
void set_CG_char(char c, __code char * map) {
    unsigned char i = 0;
    c = c * 8; // Starting point for CGRAM
    IO_M = 1;
    for( i = 0; i < 8; i++) {
        while(*LCD_BUSY & 0x80);
        *LCD_CMD = 0x40 | (c + i); // Set CGRAM address
        while(*LCD_BUSY & 0x80);
        *LCD_DATA = *(map + i); // Set character code
    }
    while(*LCD_BUSY & 0x80);
    *LCD_CMD = 0x80; // Back to DDRAM
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
    __xdata unsigned char * i = 0x0000;
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
/* memory_dump_line
 * Dumps a specified number of bytes starting at start from external memory
 * start: address to start dump from
 * num_bytes: number of bytes to dump ( < 4) 
 * line: the line we want to print on
 */
void memory_dump_line(__xdata char * start, unsigned char num_bytes, char line) {
    char line_start;
    char current;
    unsigned char i;
    IO_M = 0;
    line_start = *(LCD_LINES + line);
    set_LCD_line(line);
    printf_tiny("%x", ((unsigned int)start >> 12) & 0x000F ); // print address
    printf_tiny("%x", ((unsigned int)start >> 8) & 0x000F ); // print address
    printf_tiny("%x", ((unsigned int)start >> 4) & 0x000F ); // print address
    printf_tiny("%x", ((unsigned int)start) & 0x000F ); // print address
    for(i = 0; i < num_bytes; i++) {
        current = *(start + i);
        set_LCD_cursor(line_start + 5 + i * 3);
        printf_tiny("%x", current & 0xff); // Print hex
        set_LCD_cursor(line_start + 16 + i);
        if(0x7F > current && current > 0x19) {
            printf_tiny("%c", current & 0xff);
        } else {
            putchar('.');
        }
        
    }
    return;
}
void move_memory(__xdata char * src, __xdata char * dest, unsigned char num_bytes) {
    unsigned char i = 0;
    char temp = 0;
    IO_M = 0;
    for(i = 0; i < num_bytes; i++) {
        temp = *(src + i);
        *(dest + i) = temp;
    }
    return;
}
void edit_memory(__xdata char * dest, char val) {
    IO_M = 0;
    *dest = val;
    return;
}
int search_memory(__xdata char * start, char val, unsigned char num_bytes) {
    unsigned char i = 0;
    IO_M = 0;    
    F0 = 0;
    for(i = 0; i < num_bytes; i++) {
        if(*(start + i) == val) {
            return (int)(start + i);
        }
    }
    F0 = 1;
    return 0xFFFF;
    
}