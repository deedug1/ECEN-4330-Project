#include <stdio.h>
#include <8051.h>

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

// Keys for KEYPADSTATE
#define KEY_1 (1 << 0)
#define KEY_4 (1 << 1)
#define KEY_7 (1 << 2)
#define KEY_F (1 << 3)
#define KEY_2 (1 << 4)
#define KEY_5 (1 << 5)
#define KEY_8 (1 << 6)
#define KEY_0 (1 << 7)
#define KEY_3 (1 << 8)
#define KEY_6 (1 << 9)
#define KEY_9 (1 << 10)
#define KEY_E (1 << 11)
#define KEY_A (1 << 12)
#define KEY_B (1 << 13)
#define KEY_C (1 << 14)
#define KEY_D (1 << 15)

// type state
struct state;
typedef void state_fn(void);
struct state {
    state_fn * next;
    int i;
};

// External Hardware addresses
__xdata unsigned char * __code LCD_BUSY = 0x2002;
__xdata unsigned char * __code LCD_CMD = 0X2000;
__xdata unsigned char * __code LCD_DATA = 0x2001;
__xdata unsigned char * __code LCD_COLOR = 0x4000;
__xdata unsigned char * __code SEG_DISPLAY = 0x0000;
__xdata unsigned char * __code ADC = 0x6000;
__xdata unsigned char * __code RTC = 0x8000;

// Constants and Tables
__code unsigned char LCD_LINES[] = {0x00, 0x40, 0x14, 0x54}; // Starting point for each line on the LCD
__code unsigned char KEYPAD_CHARS[] = { '1', '4', '7', 'F',
                                        '2', '5', '8', '0',
                                        '3', '6', '9', 'E',
                                        'A', 'B', 'C', 'D', 'X' }; // X should not be accessable
__code unsigned char KEYPAD_HEX[] = {   0x01, 0x04, 0x07, 0x0F,
                                        0x02, 0x05, 0x08, 0x00,
                                        0x03, 0x06, 0x09, 0x0E,
                                        0x0A, 0x0B, 0x0C, 0x0D, 0xFF}; // 0xFF should not be accessable
__code unsigned char HOME[] =   {0x00, 0x04, 0x0A, 0x11, 0x0E, 0x0E, 0x00, 0x00}; // Home Icon
__code unsigned char SMILE[] =  {0x00, 0x00, 0x0A, 0x0A, 0x11, 0x0E, 0x00, 0x00}; // Smile Icon
__code unsigned char WORK[] =   {0x1F, 0x11, 0x15, 0x15, 0x11, 0x15, 0x11, 0x1F}; // Work Icon

// Special function register locations
__sbit __at (0xB5) IO_M;
__sfr __at (0x90) P1;
__sfr __at (0xF0) BREG;

// Global variables
unsigned int __xdata KEYPAD_STATE; // State of keypad since last scan
int __xdata whole_temp; // whole part of temperature
int __xdata frac_temp; // Fraction part of temperature
char __xdata last_key; // Last Keypad index since last scan
__xdata unsigned char parity;
// Delays
void delay1ms();
void delay(int x);

// LCD interfacing functions
void init_LCD();
void clear_LCD();
void clear_line(char line);
void set_LCD_line(char line);
void set_LCD_cursor(char loc);
void putchar(char c);
void print_byte(unsigned char byte);
void print_word(unsigned int word);
void set_CG_char(char c, __code char * map);

// Keypad interfacing functions
char set_keypad_state_nb();
char set_keypad_state_b();
char is_pressed(int key);
void get_address(char * msg, char * rng, __xdata char ** put, char line);
void get_byte(char * msg, char * rng, char * put, char line);
char get_string(__xdata char * str);
void scan_keypad();

// RTC interfacing functions
void init_RTC();
void while_rtc_busy();
char read_rtc(char reg);

// 7Seg functions...
void change_display(char c);

// ADC interfacing functions
void do_conversion(int * whole, int * frac);

// Serial functions
void set_baud(unsigned int baud);
void set_parity(unsigned char par);
void init_uart(unsigned int baud, unsigned char par);
void enable_recieve();
char recieve_char(char * data);
void send_char(unsigned char data);
char recieve_string(char * data);
void send_string(char * data);

// Memory Functions
char ram_test();
void memory_dump_line( __xdata char * start, unsigned char num_bytes, char line);

// Programs
void main_menu(void);
void debug(void);
void dump_program(void);
void search_program(void);
void edit_program(void);
void move_program(void);
void set_RTC_program(void);
void time_temp_program(void);
void serial_program(void);
void serial_char_program(void);
void oregon_program(void);

// Program menu
__code state_fn * programs[] = {dump_program, search_program, edit_program, move_program, fill_program, 
                               time_temp_program, serial_program, serial_char_program, debug}; 
__code char * program_strings[] = { "Dump","Search", "Edit", "Move", "Fill",
                                    "Time & Temp", "Serial", "Serial C", "Debug"};
__code unsigned char num_programs = 9;

// Current Program state
struct state __xdata state;
int main(void) {
    // Init hardware
    init_LCD(); 
    init_RTC();
    *LCD_COLOR = 0x04; // Set yellow screen
    // Test Ram
    clear_LCD();
    if(ram_test() != 0) {
        set_LCD_line(0);
        printf_tiny("  RAM TEST FAILED  ");
        set_LCD_line(1);
        printf_tiny("    GET NEW RAM    ");
        while(1); // Loop for enternity you failure
    }
    // Set first state
    state.next = main_menu; 
    state.i = 0;
    // Load custom characters
    set_CG_char(0, HOME);
    set_CG_char(1, SMILE);
    set_CG_char(2, WORK);
    while(1) {
        KEYPAD_STATE = 0xFFFF; // Reset keypad state incase the next program immediatly looks for input
        state.next();
    }
}

/**
 * Main menu
 * Home screen of the system all programs are selected from this screen
 **/
void main_menu(void) {
    unsigned char index = 0;
    clear_LCD();
    set_LCD_line(0);
    printf_tiny("Welcome %c!", 0x01);
    set_LCD_line(1);
    printf_tiny("Pick(F) a program %c!", 0x01);
    set_LCD_line(2);
    printf_tiny("Prev(1) Next(2)");
    while(!is_pressed(KEY_F)) {
        clear_line(3);
        printf_tiny(*(program_strings + index));
        set_keypad_state_b();
        if(is_pressed(KEY_1)) {
            index = index == 0 ? num_programs - 1 : index - 1;
        } else if(is_pressed(KEY_2)) {
            index++;   
        }
        index = index % num_programs;
    }
    IO_M = 0;
    state.next = programs[index];
    return;
}
char get_string(__xdata char * str) {
    char count = 0;
    do {
        get_byte("", "", str, 0);
        set_LCD_cursor(0x54 + count);
        printf_tiny("%c", *str);
        str++;
        
    } while(*(str - 1) != '\0' && ++count < 20);
    *str = '\0';
    return count;
}
void get_address(char * msg, char * rng, __xdata char ** put, char line) {
    char index = 0;
    do {
        *(put) = 0; 
        clear_line(line + 2);
        clear_line(line + 1); 
        printf_tiny("%s", rng);       
        clear_line(line);
        printf_tiny("%s", msg);
        for(index = 3; index >= 0; index--) {
            set_keypad_state_b();
            *(put) += (*(last_key + KEYPAD_HEX) << (index * 4));
            putchar(*(last_key + KEYPAD_CHARS));
        }
        clear_line(line + 2);
        printf_tiny("Redo(F) Confirm(any)");
        set_keypad_state_b();
    } while(is_pressed(KEY_F)); // Submit confirmation

    return;
}
void get_byte(char * msg, char * rng, char * put, char line) {
    char index = 0;
    do {
        *(put) = 0;
        clear_line(line + 2);
        clear_line(line + 1);
        printf_tiny("%s", rng);        
        clear_line(line);
        printf_tiny("%s", msg);
        for(index = 1; index >= 0; index--) {
            set_keypad_state_b();
            *(put) +=(*(last_key + KEYPAD_HEX) << (index * 4));
            putchar(*(last_key+KEYPAD_CHARS));
        }
        clear_line(line + 2);
        printf_tiny("Redo(F) Confirm(any)");
        set_keypad_state_b();
    } while(is_pressed(KEY_F)); // Submit confirmation
}

/**
 * Debug Program
 * Program used to test that the hardware of the system is functioning
 **/
void debug(void) {
    __xdata char * dump_index = 0;
    char index = 0;
    char seg = 0x01;
    clear_LCD();
    KEYPAD_STATE = 0xFFFF;
    while(!is_pressed(KEY_A)){
        do_conversion(&whole_temp, &frac_temp); // Update temperature
        set_LCD_line(0);
        printf_tiny("%d%d", read_rtc(H10), read_rtc(H1));
        printf_tiny(":%d%d:", read_rtc(MI10), read_rtc(MI1));
        printf_tiny("%d%d", read_rtc(S10), read_rtc(S1)); // Print HH:Mi:SS
        set_LCD_line(1);
        printf_tiny("%d.%d", whole_temp, frac_temp); // Print Temperature
        set_LCD_line(2);
        set_keypad_state_nb(); // Update keypad state
        putchar(*(last_key + KEYPAD_CHARS)); // Print Keypad state
        memory_dump_line(dump_index, 4, 3); // Dump a Line of memory
        dump_index = dump_index + 4;
        change_display(seg);
        seg = seg == 0 ? 1 : seg << 1;
        delay(100);
    }
    state.next = main_menu;
    change_display(0xFF);
    return;   
}
void serial_char_program(void) {
    __xdata char data_out;
    __xdata char data_in;
    init_uart(9600, 0); // 9600 no parity
    enable_recieve();
    do {
        data_out = 0;
        data_in = 0;
        get_byte("Send?", "", &data_out, 0);
        if(data_out) {
            clear_LCD();
            send_char(data_out);
            recieve_char(&data_in);
            set_LCD_line(3);
            printf_tiny("%x %x",data_in, data_out);
            set_keypad_state_b();
        }
    } while(data_out);
    state.next = main_menu;
    return;
}
void serial_program(void) {
    __xdata char * baud;
    __xdata char str[21];
    get_address("Enter baud", "(0x04B0-0x4B00)", &baud, 0);
    get_byte("Enter parity: ", "0=none,1=odd,2=even", &parity, 0);
    init_uart((int)baud, parity);
    enable_recieve();
    do {
    clear_LCD();
    printf_tiny("0: Send String");
    set_LCD_line(1);
    printf_tiny("1: Recieve String");
    set_LCD_line(2);
    printf_tiny("A: Go home");
    set_LCD_line(3);
    printf_tiny("TH1: %dparity: %d", TH1, (int)parity);
        set_keypad_state_b();
        if(is_pressed(KEY_0)) {
            clear_LCD();
            get_string(str);
            send_string(str);
        } else if(is_pressed(KEY_1)) {
            clear_LCD();
            recieve_string(str);
            set_LCD_line(3);
            printf_tiny("%s", str);
            set_keypad_state_b();
        }
    } while(!is_pressed(KEY_A));
    state.next = main_menu;
    return;
}
/**
 * Dump Program
 * Program used to display contents of RAM
 **/
void dump_program(void) {
    // local vars
    __xdata char * start = 0;
    __idata input = 0;
    clear_LCD();
    get_address("Enter Address: ","(0000-FFFF)", &start, 0);
    clear_line(0);
    printf_tiny("Prev(1) Next(2) %c(A)", 0x00);
    do {
        // Display
        memory_dump_line(start, 4, 1);
        start += 4;
        memory_dump_line(start, 4, 2);
        start += 4;
        memory_dump_line(start, 4, 3);
        start += 4;
        do {
            // Request next step
            set_keypad_state_b();
            if(is_pressed(KEY_1)) {
                start -= 24; // Move back
                input = 1;
            } else if(is_pressed(KEY_A)) {
                input = 0xFF;
                state.next = main_menu;
            } else if(is_pressed(KEY_2)) {
                input = 1; // Move forward
            }
        } while(input == 0); 
    } while(input != 0xFF);
    return;
}

/**
 * Search Program
 * Program used to search contents of RAM
 **/
void search_program(void) {
    __xdata unsigned char * start = 0;
    unsigned int count = 0;
    unsigned char search = 0;
    char found = 0;
    char input = 0;
    clear_LCD();
    get_byte("Enter Search Val: ","00-FF", &search, 0);
    do {
        count = 0;
        clear_line(1);
        printf_tiny("Searching...");
        do {
            found = (*(start) == search);
            start++;
            count--; // fixes not found bug when using continue feature
        } while( found == 0 && count > 0x0000); // Search whole memory
        clear_line(0);
        print_byte(search);
        if(found) {
            start--; // Move back to where it was last found
            printf_tiny(" Found @ ");
            print_word((unsigned int)start);
            start++; // So that we can search again
        } else {
            printf_tiny(" Not Found");
        }
        clear_line(1);
        printf_tiny("Next location(0)");
        clear_line(2);
        printf_tiny("New Search(1) %c(A)", 0x00);
        do {
            found = 2;
            set_keypad_state_b();
            // Using found as state value
            if(is_pressed(KEY_1)) {
                state.next = search_program;
                found = 1;
            } else if(is_pressed(KEY_0)) {
                state.next = search_program;
                found = 0;
            } else if (is_pressed(KEY_A)) {
                state.next = main_menu;
                found = 1;
            }
        }while(found == 2);
    } while(found == 0);
    return;
}

/**
 * Move Program
 * Program used to duplicate blocks of RAM
 **/
void move_program(void) {
    __xdata char * start = 0;
    __xdata char * dest = 0;
    char index = 0;
    unsigned char block_size = 0;
    clear_LCD();
    get_address("Enter Src: ","(0000-FFFF)", &start, 0);
    get_address("Enter Dest: ","(0000-FFFF)", &dest, 0);
    do {
        get_byte("Block Size: ","(01-FF)", &block_size, 0);
    } while(block_size == 0);
    while(block_size --> 0) {
        *(dest + block_size) = *(start + block_size);
    }
    clear_LCD();
    set_LCD_line(0);
    printf_tiny("Move Complete %c", 0x01);
    set_LCD_line(1);
    printf_tiny("Again?(0) %c(A)", 0x00);
    do {
      set_keypad_state_b();
      if(is_pressed(KEY_0)) {
          state.next = move_program;
          index = 1;
      } else if(is_pressed(KEY_A)){
          state.next = main_menu;
          index = 1;
      }
    } while(index == 0);
    return;
}

/**
 * Edit Program
 * Program used to edit contents of RAM byte by byte
 **/
void edit_program(void) {
    __xdata char * start = 0;
    char index = 0;
    char newVal = 0;
    clear_LCD();
    get_address("Enter Address: ","(0000-FFFF)", &start, 0);
    do {
        index = 0;
        clear_line(0);
        printf_tiny("Current Address:");
        print_word((unsigned int)start);
        get_byte("New val: ","(00-FF)", &newVal, 1);
        *start = newVal;
        clear_line(2);
        printf_tiny("Edit Complete!");
        clear_line(3);
        printf_tiny("Edit Next?(0) %c(A)", 0x00);
        do {
            set_keypad_state_b();
            if(is_pressed(KEY_0)) {
                start++;
                index = 1;
            } else if(is_pressed(KEY_A)) {
                state.next = main_menu;
                index = -1;
            }
        } while(index == 0);
        clear_line(3);        
    } while(index != -1);
    return;
}

/**
 * Fill Program
 * Program used to edit blocks of RAM
 **/
void fill_program(void) {
    __xdata char * start;
    char val;
    unsigned char block_size;
    char index = 0;
    clear_LCD();
    get_address("Enter Address: ","(0000-FFFF)", &start, 0);
    get_byte("Enter Fill Val: ","(00-FF)", &val, 0);
    do {
        get_byte("Block Size: ","(01-FF)", &block_size, 0);
    } while(block_size == 0);
    while(block_size --> 0) {
        *(start + block_size) = val;
    }
    clear_LCD();
    set_LCD_line(0);
    printf_tiny("Fill Complete %c", 0x01);
    set_LCD_line(1);
    printf_tiny("Again?(0) %c(A)", 0x00);
    do {
      set_keypad_state_b();
      if(is_pressed(KEY_0)) {
          state.next = fill_program;
          index = 1;
      } else if(is_pressed(KEY_A)){
          state.next = main_menu;
          index = 1;
      }
    } while(index == 0);
    return;
    
}



/**
 * Time & Temp Program
 * Program used to display temperature and system uptime
 **/
void time_temp_program(void) {
    clear_LCD();
    set_LCD_line(2);
    printf_tiny("Hold \"A\" to go %c", 0x00);
    do {
        do_conversion(&whole_temp, &frac_temp);
        clear_line(0);
        printf_tiny("%d.%d C", whole_temp, frac_temp);
        clear_line(1);
        printf_tiny("%d%d", read_rtc(H10), read_rtc(H1));
        printf_tiny(":%d%d:", read_rtc(MI10), read_rtc(MI1));
        printf_tiny("%d%d", read_rtc(S10), read_rtc(S1));
        set_keypad_state_nb();
        delay(20);
    } while(!is_pressed(KEY_A));
    state.next = main_menu;
    return;
}
// Not done / ideas for programs
void set_RTC_program(void) {
    oregon_program();
    return;
}

void oregon_program(void) {
    char i = 0;
    clear_LCD();
    set_LCD_line(0);
    for(i = 0; i < 20; i++) {
        putchar(0x02);
    }
    set_LCD_line(1);
    printf_tiny(" Under construction ");
    set_LCD_line(2);
    printf_tiny("   comeback later   ");
    set_LCD_line(3);
    for(i = 0; i < 20; i++) {
        putchar(0x02);
    }
    set_keypad_state_b();
    state.next = main_menu;
    return;
}

// Start of helper functions
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
void putchar(char c) {
    IO_M = 1;
    while(*LCD_BUSY & 0x80); // Waits until the LCD is not busy
    *LCD_DATA = c;
    IO_M = 0;
    return;
}
void print_word(unsigned int word) {
    printf_tiny("%x", (word >> 12) & 0x000F ); // print address
    printf_tiny("%x", (word >> 8) & 0x000F ); // print address
    printf_tiny("%x", (word >> 4) & 0x000F ); // print address
    printf_tiny("%x", word & 0x000F ); // print address
}
void print_byte(unsigned char byte) {
    printf_tiny("%x", (byte >> 4) & 0x0F);
    printf_tiny("%x", (byte) & 0x0F);
    return;
}
char is_pressed(int key) {
    return (KEYPAD_STATE & key) == 0;
} 
char set_keypad_state_b() {
    unsigned char index = 0;
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
    index = 0;
    while(1) {
        if((KEYPAD_STATE & (0x0001 << index)) == 0) {
            last_key = index;
            return last_key;
        }
        index++;
    }
}
char set_keypad_state_nb() {
    unsigned char index = 0;
    scan_keypad();
    scan_keypad();
    scan_keypad(); // Allow for bouncing
    while(1) {
        if((KEYPAD_STATE & (0x0001 << index)) == 0) {
            last_key = index;
            return last_key;
        }
        index++;
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
void clear_line(char line) {
    set_LCD_line(line);
    printf_tiny("                    ");
    set_LCD_line(line);
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
void set_baud(unsigned int baud) {
    char val;
    if(baud > 2389) {
        PCON = PCON | SMOD;
        val = 57600 / baud;
    } else {
        PCON = PCON & !SMOD;
        val = 28800 / baud;
    }
    TH1 = -val;
}
void set_parity(unsigned char par) {
    parity = par;
}
void enable_recieve() {
    REN = 1;
}
void init_uart(unsigned int baud, unsigned char par) {
    // Setup Serial config
    SCON = 0x00; // Clear Serial config
    set_parity(par);
    if(parity == 0) {
        // Set mode 1
        SM0 = 0; SM1 = 1;
    } else {
        // Set mode 3
        SM0 = 1; SM1 = 1;
    }

    // Setup baudrate generator
    TMOD = 0x20;    // Set 8-bit autoreload mode
    set_baud(baud); // Load timer with divider value
    TR1 = 1;        // Start timer
}
void send_string(char * data){
    while(*data != '\0') {
        send_char(*data);
        data++;
    }
}
char recieve_string(char * data) {
    char count = 0;
    do {
        recieve_char(data);
        data++;
    } while(*(data - 1) != '\0');
    *data = '\0';
    return count;
}
void send_char(unsigned char data) {
    ACC = data;
    // Parity flag checks accumulator for even parity
    if(parity == 1) {
        TB8 = !P; // Odd parity
    } else if(parity == 2) {
        TB8 = P; // Even parity
    }
    SBUF = data;         // Send data
    while(!(TI));       // Wait to finish sending
    TI = 0;// Clear for next send
}
char recieve_char(char * data) {
    char result = 0;
    while(!(RI));           // Wait for data
    *data = SBUF;           // Store data
    ACC = *data;
    if(parity == 1) {
        result = !P == RB8;
    } else if (parity == 2) {
        result = P == RB8;
    } else {
        result = 1;
    }
    RI = 0;    // Clear for next recieve
    return result;
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
void memory_dump_line(__xdata char * start, unsigned char num_bytes, char line) {
    char line_start;
    char current;
    unsigned char i;
    IO_M = 0;
    line_start = *(LCD_LINES + line);
    clear_line(line);
    print_word((unsigned int)start);
    for(i = 0; i < num_bytes; i++) {
        current = *(start + i);
        set_LCD_cursor(line_start + 5 + i * 3);
        print_byte(current);
        set_LCD_cursor(line_start + 16 + i);
        if(0x7F > current && current > 0x19) {
            printf_tiny("%c", current & 0xff);
        } else {
            putchar('.');
        }
        
    }
    return;
}