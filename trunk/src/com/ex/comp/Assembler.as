/* ========================================================================== */
/*   Assembler.as                                                             */
/*   Simple assembler in two steps with minimal error detection.              */
/*   Copyright (c) 2010 Laurens Rodriguez Oscanoa.                            */
/* -------------------------------------------------------------------------- */
/*   This code is licensed under the MIT license:                             */
/*   http://www.opensource.org/licenses/mit-license.php                       */
/* -------------------------------------------------------------------------- */

package com.ex.comp {

public class Assembler {

    private static const TOKEN_COMMENT:String = "/";
    private static const TOKEN_LABEL:String = ":";
    private static const PSEUDO_INSTRUCTIONS:Array = [
        "DEC",
        "HEX",
        "ORG",
        "LBL"
    ];
    private static const MRI_INSTRUCTIONS:Array = [
        "AND",
        "ADD",
        "LDA",
        "STA",
        "BUN",
        "BSA",
        "ISZ"
    ];
    private static const MRI_CODES:Array = [
        0x0000,
        0x1000,
        0x2000,
        0x3000,
        0x4000,
        0x5000,
        0x6000
    ];
    private static const RRI_INSTRUCTIONS:Array = [
        "CLA",
        "CLE",
        "CMA",
        "CME",
        "CIR",
        "CIL",
        "INC",
        "SPA",
        "SNA",
        "SZA",
        "SZE",
        "HLT",
        "INP",
        "OUT",
        "SKI",
        "SKO",
        "ION",
        "IOF"
    ];
    private static const RRI_CODES:Array = [
        0x7800,
        0x7400,
        0x7200,
        0x7100,
        0x7080,
        0x7040,
        0x7020,
        0x7010,
        0x7008,
        0x7004,
        0x7002,
        0x7001,
        0xF800,
        0xF400,
        0xF200,
        0xF100,
        0xF080,
        0xF040
    ];

    private var mInitAddress:uint = 0;
    private var mBinaryProgram:Array = null;
    private var mAddressList:Array = null;
    private var mParent:Computer = null;
    private var mLabelsInfo:String;

    public function get initAddress():uint { return mInitAddress; }
    public function get codes():Array { return mBinaryProgram; }
    public function get addresses():Array { return mAddressList; }
    public function get labels():String { return mLabelsInfo; }

    public function Assembler(parent:Computer) {
        mBinaryProgram = new Array();
        mAddressList = new Array();
        mParent = parent;
    }

    public function assemble(program:String):Boolean {
        // Split in lines, converting tabs to spaces.
        var lines:Array = program.replace(/\t/g, " ").split("\r");

        // Strip commentaries.
        for (var k:int = 0; k < lines.length; ++k) {
            var line:String = lines[k];
            if (line.indexOf(TOKEN_COMMENT) >= 0) {
                line = line.substr(0, line.indexOf(TOKEN_COMMENT));
            }
            if (line.replace(/\s/g, "").length == 0) {
                lines[k] = null;
            } else {
                lines[k] = line;
            }
        }

        if (lines.length > 0) {
            // Clear last stored program.
            mBinaryProgram.length = 0;
            mAddressList.length = 0;

            // FIRST PASS
            // -----------------------------------------------------------------
            var labels:Array = new Array();
            var dirs:Array = new Array();
            var lineNumber:int = 0;
            var lineAddress:int = 0;
            var iniLine:int = 0;
            var endLine:int = 0;

            // Set default initial address.
            lineAddress = mInitAddress = 0;

            // Skip empty lines.
            while (lines[lineNumber] == null && lineNumber < lines.length) {
                ++lineNumber;
            }

            // Check if initial address is declared. (It must be first instruction)
            if (String(lines[lineNumber]).search(/ORG/i) >= 0) {
                var regex:RegExp = /^[\s]*ORG[\s]+([abcdef\d]+)[\s]*$/i;
                var catches:Array = regex.exec(lines[lineNumber]);
                if (catches) {
                    // Address must be in hex.
                    lineAddress = mInitAddress = Number("0x" + catches[1]);
                    trace("InitAddress: "+mInitAddress);
                    ++lineNumber;
                    iniLine = lineNumber;
                }
                else {
                    mParent.onError("Line(" + (lineNumber + 1) + ") ORG address is not a valid hex number.");
                    return false;
                }
            }

            mLabelsInfo = "";
            for (; lineNumber < lines.length; ++lineNumber) {
                regex = /^[\s]*([a-z\d_]+):.*/i;
                catches = regex.exec(lines[lineNumber]);
                if (catches) {
                    labels.push(catches[1]);
                    dirs.push(lineAddress);
                    var pad:String = "";
                    while (pad.length < 9 - catches[1].length) { pad += " "; }
                    mLabelsInfo += catches[1] + ":" + pad + lineAddress.toString(16).toUpperCase() + "\n";
                }
                if (lines[lineNumber] != null) {
                    ++lineAddress;
                    if (String(lines[lineNumber]).search(/END/i) >= 0) {
                        endLine = lineNumber;
                        break;
                    }
                }
            }

            // SECOND PASS
            // -----------------------------------------------------------------
            if (endLine > 0) {
                lineAddress = mInitAddress;

                for (lineNumber = iniLine; lineNumber < endLine; ++lineNumber) {
                    if (lines[lineNumber] != null) {
                        line = lines[lineNumber];

                        // Strip labels.
                        if (line.indexOf(TOKEN_LABEL) >= 0) {
                            line = line.substr(line.indexOf(TOKEN_LABEL) + 1);
                        }

                        // Trim split in tokens.
                        line = line.replace(/^([\s]+)?(\S.*\S)([\s]+)?$/g, "$2");
                        var tokens:Array = line.split(" ");
                        trace(tokens);
                        if (tokens.length < 1 || tokens.length > 3) {
                            mParent.onError("Line(" + (lineNumber + 1) + ") invalid line: "+lines[lineNumber]);
                            return false;
                        }

                        // Check if it is pseudocode.
                        var index:int = PSEUDO_INSTRUCTIONS.indexOf(tokens[0]);
                        if (index >= 0) {
                            if (tokens.length == 2) {
                                var data:Number;
                                switch (index) {
                                case 0: // DEC
                                    data = Number(tokens[1]);
                                    break;
                                case 1: // HEX
                                    data = Number("0x" + tokens[1]);
                                    break;
                                case 2: // ORG
                                    lineAddress = Number("0x" + tokens[1]);
                                    if (!isNaN(lineAddress)) {
                                        continue;
                                    }
                                    mParent.onError("Line(" + (lineNumber + 1) + ") invalid ORG: "+lines[lineNumber]);
                                    return false;
                                case 3: // LBL
                                    // Look for label.
                                    index = labels.indexOf(tokens[1]);
                                    if (index >= 0) {
                                        data = dirs[index];
                                    }
                                    else {
                                        mParent.onError("Line(" + (lineNumber + 1) + ") can't find label: " + tokens[1]);
                                        return false;
                                    }
                                    break;
                                }
                                if (!isNaN(data)) {
                                    mBinaryProgram.push(data);
                                    mAddressList.push(lineAddress++);
                                    continue;
                                }
                            }
                            mParent.onError("Line(" + (lineNumber + 1) + ") invalid HEX or DEC: "+lines[lineNumber]);
                            return false;
                        }

                        // Check if it is a register instruction.
                        index = RRI_INSTRUCTIONS.indexOf(tokens[0]);
                        if (index >= 0) {
                            if (tokens.length == 1) {
                                mBinaryProgram.push(RRI_CODES[index]);
                                mAddressList.push(lineAddress++);
                                continue;
                            }
                            mParent.onError("Line(" + (lineNumber + 1) + ") invalid RRI: "+lines[lineNumber]);
                            return false;
                        }

                        // Check if it is a memory instruction.
                        index = MRI_INSTRUCTIONS.indexOf(tokens[0]);
                        if (index >= 0) {
                            if (tokens.length == 2 || tokens.length == 3) {
                                // Look for label.
                                var labelIndex:int = labels.indexOf(tokens[1]);
                                if (labelIndex >= 0) {
                                    if (tokens.length == 2) {
                                        mBinaryProgram.push(MRI_CODES[index] | dirs[labelIndex]);
                                        mAddressList.push(lineAddress++);
                                        continue;
                                    }
                                    else {
                                        if (tokens[2] == "I") {
                                            mBinaryProgram.push(0x8000 | MRI_CODES[index] | dirs[labelIndex]);
                                            mAddressList.push(lineAddress++);
                                            continue;
                                        }
                                    }
                                }
                                else {
                                    mParent.onError("Line(" + (lineNumber + 1) + ") can't find label: " + tokens[1]);
                                    return false;
                                }
                            }
                            mParent.onError("Line(" + (lineNumber + 1) + ") invalid MRI: "+lines[lineNumber]);
                            return false;
                        }
                    }
                }
                return true;
            }
            else {
                mParent.onError("END was not found.");
            }
        }
        return false;
    }
}
}

