// Kurzweil K2000r SysEx Programmer with Screen Display
// Initialize MIDI first
(
// Connect to MIDI - adjust port number as needed
MIDIClient.init;
MIDIIn.connectAll;

// List all available MIDI ports
"Available MIDI destinations:".postln;
MIDIClient.destinations.do({|endpoint, i|
    postln("Port " ++ i ++ ": " ++ endpoint.name ++ " - " ++ endpoint.device);
});

// Find your K2000r MIDI output port
m = MIDIOut(2); // Change this to match your K2000r's port number
m.latency = 0;

"Selected MIDI port: ".post;
MIDIClient.destinations[0].postln;

// Screen buffer to store K2000r display text
~screenBuffer = Array.fill(2, {Array.fill(40, $ )}); // 2 lines, 40 chars each
~cursorPos = [0, 0]; // [line, column]

// K2000r SysEx helper function
// Format: F0 07 00 [deviceID] 14 09 [command] 7F F7
// Default device ID is 00, but may need to match your K2000r's setting
~k2kDeviceID = 0x00; // Change if needed (0x00 to 0x7F)

~k2kSysex = {|cmd|
    var msg = [0xF0, 0x07, ~k2kDeviceID, 0x14, 0x09, cmd, 0x7F, 0xF7];
    ("Sending SysEx: " ++ msg.collect(_.asHexString(2))).postln;
    m.sysex(Int8Array.newFrom(msg));
};

// Function to update screen display
~updateScreen = {
    var line1 = ~screenBuffer[0].collect(_.asString).join("");
    var line2 = ~screenBuffer[1].collect(_.asString).join("");
    {
        ~screenLine1.string_(line1);
        ~screenLine2.string_(line2);
    }.defer;
};

// MIDI responder for screen updates from K2000r
// K2000r sends display data as SysEx: F0 07 00 78 14 10 [line] [data...] F7
~midiResp = MIDIFunc.sysex({|uid, src|
    var data = uid;
    // Check if it's a K2000r display message (manufacturer ID: 07 00 78)
    if((data[1] == 0x07) && (data[2] == 0x00) && (data[3] == 0x78) && (data[4] == 0x14) && (data[5] == 0x10), {
        var line = data[6]; // 0 or 1 for line number
        var textData = data[7..(data.size-2)]; // Remove F0 and F7

        if(line < 2, {
            textData.do({|char, i|
                if(i < 40, {
                    ~screenBuffer[line][i] = char.asAscii;
                });
            });
            ~updateScreen.value;
        });
    });
});

// Request screen dump from K2000r
~requestScreen = {
    // Send request for display data (if K2000r supports this)
    m.sysex(Int8Array.newFrom([0xF0, 0x07, ~k2kDeviceID, 0x14, 0x10, 0x00, 0xF7]));
};

// Create the main window
w = Window("K2000r SysEx Programmer", Rect(100, 100, 700, 850))
.layout_(
    VLayout(

        // Title
        StaticText().string_("Kurzweil K2000r Remote Control").font_(Font.default.size_(16)).align_(\center),

        // LCD Screen Display
        VLayout(
            StaticText().string_("K2000r Display").font_(Font.default.size_(12)).align_(\center),

            // LCD background container
            View()
                .background_(Color.new(0.3, 0.4, 0.3)) // LCD green background
                .layout_(
                    VLayout(
                        ~screenLine1 = StaticText()
                            .string_("                                        ")
                            .font_(Font("Courier New", 18))
                            .stringColor_(Color.black)
                            .background_(Color.new(0.6, 0.8, 0.6))
                            .align_(\left),

                        ~screenLine2 = StaticText()
                            .string_("                                        ")
                            .font_(Font("Courier New", 18))
                            .stringColor_(Color.black)
                            .background_(Color.new(0.6, 0.8, 0.6))
                            .align_(\left)
                    )
                )
                .minHeight_(100),

            // Screen control buttons
            HLayout(
                Button()
                    .string_("Request Screen")
                    .action_({~requestScreen.value}),

                Button()
                    .string_("Clear Screen")
                    .action_({
                        ~screenBuffer = Array.fill(2, {Array.fill(40, $ )});
                        ~updateScreen.value;
                    }),

                Button()
                    .string_("Test MIDI")
                    .action_({
                        // Send a simple note on/off to test connection
                        m.noteOn(0, 60, 100);
                        {m.noteOff(0, 60, 0)}.defer(0.5);
                        "Sent test MIDI note".postln;
                    })
            )
        ),

        // Channel/Bank buttons
        HLayout(
            StaticText().string_("Device ID:"),
            ~deviceIDNum = NumberBox()
                .value_(0)
                .decimals_(0)
                .minWidth_(50)
                .action_({|nb| ~k2kDeviceID = nb.value.asInteger}),

            ~allText = Button()
                .string_('All Text')
                .action_({~k2kSysex.(0x15)}),

            ~chanUp = Button()
                .string_("Chan/Bank +")
                .action_({~k2kSysex.(0x14)}),

            ~chanDown = Button()
                .string_("Chan/Bank -")
                .action_({~k2kSysex.(0x15)})
        ),

        // Function buttons row
        HLayout(
            ~edit = Button()
                .string_("Edit")
                .action_({~k2kSysex.(0x20)}),

            ~f1 = Button()
                .string_("< More")
                .action_({~k2kSysex.(0x22)}),

            ~f2 = Button()
                .string_("F1")
                .action_({~k2kSysex.(0x23)}),

            ~f3 = Button()
                .string_("F2")
                .action_({~k2kSysex.(0x24)}),

            ~f4 = Button()
                .string_("F3")
                .action_({~k2kSysex.(0x25)}),

            ~f5 = Button()
                .string_("F4")
                .action_({~k2kSysex.(0x26)}),

            ~f6 = Button()
                .string_("More >")
                .action_({~k2kSysex.(0x27)}),

            ~exit = Button()
                .string_("Exit")
                .action_({~k2kSysex.(0x21)})
        ),

        // Mode buttons
        HLayout(
            ~program = Button()
                .string_("Program\nMute 1")
                .action_({~k2kSysex.(0x40)}),

            ~setup = Button()
                .string_("Setup\nMute 2")
                .action_({~k2kSysex.(0x41)}),

            ~qAccess = Button()
                .string_("Q-Access\nMute 3")
                .action_({~k2kSysex.(0x42)}),

            ~effects = Button()
                .string_("Effects\nFX Bypass")
                .action_({~k2kSysex.(0x47)})
        ),

        HLayout(
            ~midi = Button()
                .string_("MIDI\nPrev Page")
                .action_({~k2kSysex.(0x44)}),

            ~master = Button()
                .string_("Master\nMark")
                .action_({~k2kSysex.(0x43)}),

            ~song = Button()
                .string_("Song\nJump")
                .action_({~k2kSysex.(0x46)}),

            ~disk = Button()
                .string_("Disk\nCompare")
                .action_({~k2kSysex.(0x45)})
        ),

        // Navigation buttons
        VLayout(
            StaticText().string_("Navigation").align_(\center),

            ~up = Button()
                .string_("▲ Up")
                .action_({~k2kSysex.(0x10)}),

            HLayout(
                ~left = Button()
                    .string_("◄ Left")
                    .action_({~k2kSysex.(0x12)}),

                StaticText().string_("  "),

                ~right = Button()
                    .string_("Right ►")
                    .action_({~k2kSysex.(0x13)})
            ),

            ~down = Button()
                .string_("▼ Down")
                .action_({~k2kSysex.(0x11)})
        ),

        // Plus/Minus
        HLayout(
            ~minus = Button()
                .string_("−")
                .action_({~k2kSysex.(0x17)}),

            ~plus = Button()
                .string_("+")
                .action_({~k2kSysex.(0x16)})
        ),

        // Numeric keypad
        StaticText().string_("Numeric Keypad").align_(\center),

        HLayout(
            ~one = Button().string_("1").action_({~k2kSysex.(0x01)}),
            ~two = Button().string_("2").action_({~k2kSysex.(0x02)}),
            ~three = Button().string_("3").action_({~k2kSysex.(0x03)})
        ),

        HLayout(
            ~four = Button().string_("4").action_({~k2kSysex.(0x04)}),
            ~five = Button().string_("5").action_({~k2kSysex.(0x05)}),
            ~six = Button().string_("6").action_({~k2kSysex.(0x06)})
        ),

        HLayout(
            ~seven = Button().string_("7").action_({~k2kSysex.(0x07)}),
            ~eight = Button().string_("8").action_({~k2kSysex.(0x08)}),
            ~nine = Button().string_("9").action_({~k2kSysex.(0x09)})
        ),

        HLayout(
            ~plusminus = Button().string_("+/−").action_({~k2kSysex.(0x0A)}),
            ~zero = Button().string_("0").action_({~k2kSysex.(0x00)}),
            ~clr = Button().string_("Clear").action_({~k2kSysex.(0x0C)})
        ),

        // Cancel/Enter
        HLayout(
            ~cancel = Button()
                .string_("Cancel")
                .action_({~k2kSysex.(0x0B)}),

            ~enter = Button()
                .string_("Enter")
                .action_({~k2kSysex.(0x0D)})
        )
    )
)
.front
.alwaysOnTop_(true);

// Keyboard shortcuts
w.view.keyDownAction = {|view, char|
    case
    {char == $*} { ~chanUp.valueAction_(1) }
    {char == $/} { ~chanDown.valueAction_(1) }
    {char == $e} { ~edit.valueAction_(1) }
    {char == $q} { ~exit.valueAction_(1) }
    {char == $1} { ~one.valueAction_(1) }
    {char == $2} { ~two.valueAction_(1) }
    {char == $3} { ~three.valueAction_(1) }
    {char == $4} { ~four.valueAction_(1) }
    {char == $5} { ~five.valueAction_(1) }
    {char == $6} { ~six.valueAction_(1) }
    {char == $7} { ~seven.valueAction_(1) }
    {char == $8} { ~eight.valueAction_(1) }
    {char == $9} { ~nine.valueAction_(1) }
    {char == $0} { ~zero.valueAction_(1) }
    {char == $x} { ~clr.valueAction_(1) }
    {char == $\r} { ~enter.valueAction_(1) }
    {char == $(} { ~minus.valueAction_(1) }
    {char == $)} { ~plus.valueAction_(1) }
    {char == $-} { ~plusminus.valueAction_(1) }
    {char == $a} { ~f1.valueAction_(1) }
    {char == $s} { ~f2.valueAction_(1) }
    {char == $d} { ~f3.valueAction_(1) }
    {char == $f} { ~f4.valueAction_(1) }
    {char == $g} { ~f5.valueAction_(1) }
    {char == $h} { ~f6.valueAction_(1) }
    {char == $i} { ~up.valueAction_(1) }
    {char == $k} { ~down.valueAction_(1) }
    {char == $j} { ~left.valueAction_(1) }
    {char == $l} { ~right.valueAction_(1) }
    {char == $c} { ~cancel.valueAction_(1) }
    {char == 27.asAscii} { ~exit.valueAction_(1) }; // ESC key
};

// Cleanup function
w.onClose_({
    ~midiResp.free;
});

"K2000r SysEx Programmer with Screen Display loaded.".postln;
"Click 'Request Screen' to fetch display data from K2000r.".postln;
"Keyboard shortcuts: numbers 0-9, *, /, e(dit), q(exit), a-h(F1-F6), i/k/j/l(nav), c(ancel), Enter".postln;
)

// To close the window:
// w.close;