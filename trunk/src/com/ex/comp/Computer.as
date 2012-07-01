/* ========================================================================== */
/*                       SIMULATOR FOR BASIC COMPUTER                         */
/* -------------------------------------------------------------------------- */
/*   A simple simulator for the basic computer described in Morris Mano's     */
/*   book: Computer System Architecture (ISBN: 978-0131755635)                */
/*                                                                            */
/*   Copyright (c) 2010 Laurens Rodriguez Oscanoa.                            */
/*                                                                            */
/*   Permission is hereby granted, free of charge, to any person              */
/*   obtaining a copy of this software and associated documentation           */
/*   files (the "Software"), to deal in the Software without                  */
/*   restriction, including without limitation the rights to use,             */
/*   copy, modify, merge, publish, distribute, sublicense, and/or sell        */
/*   copies of the Software, and to permit persons to whom the                */
/*   Software is furnished to do so, subject to the following                 */
/*   conditions:                                                              */
/*                                                                            */
/*   The above copyright notice and this permission notice shall be           */
/*   included in all copies or substantial portions of the Software.          */
/*                                                                            */
/*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,          */
/*   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES          */
/*   OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                 */
/*   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT              */
/*   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,             */
/*   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING             */
/*   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR            */
/*   OTHER DEALINGS IN THE SOFTWARE.                                          */
/* -------------------------------------------------------------------------- */

package com.ex.comp {

import mx.core.UIComponent;

public class Computer extends UIComponent {
	
    private var mAR:Register = null;
    private var mPC:Register = null;
    private var mDR:Register = null;
    private var mAC:Register = null;
    private var mIR:Register = null;
    private var mTR:Register = null;
    private var mINPR:Register = null;
    private var mOUTR:Register = null;

    private var mI:Register = null;
    private var mS:Register = null;
    private var mE:Register = null;
    private var mR:Register = null;
    private var mIEN:Register = null;
    private var mFGI:Register = null;
    private var mFGO:Register = null;
    private var mSC:Register = null;

    private var mM:Memory = null;

    private var mD:uint;
    private var mTicks:uint;    // Total clock cycles.

    private var mAssembler:Assembler = null;
    private var mParent:Object = null;
    private var mProgramLoaded:Boolean = false;

    public function Computer(parent:Object) {
        mParent = parent;

        // Create computer registers.
        mAR = new Register(this, "AR", 12, 150, 15, 0xaaee88);
        mPC = new Register(this, "PC", 12, 150, 55, 0xbbff88);
        mDR = new Register(this, "DR", 16, 150, 95, 0xddffaa);
        mAC = new Register(this, "AC", 16, 150, 135, 0xeeff88);
        mIR = new Register(this, "IR", 16, 150, 175, 0xeeeeaa);
        mTR = new Register(this, "TR", 16, 150, 215, 0xeeddbb);
        mINPR = new Register(this, "INPR", 8, 150, 255, 0xffccaa, 50);
        mOUTR = new Register(this, "OUTR", 8, 150, 295, 0xffbbaa, 50);

        // Create secuence counter SC.
        mSC = new Register(this, "SC", 3, 30, 15, 0xaaee88, 24, 8);

        // Create computer flip-flops.
        mI = new Register(this, "I", 1, 30, 55, 0xbbff88, 50);
        mS = new Register(this, "S", 1, 30, 95, 0xddffaa, 50);
        mE = new Register(this, "E", 1, 30, 135, 0xeeff88, 50);
        mR = new Register(this, "R", 1, 30, 175, 0xeeeeaa, 50);
        mIEN = new Register(this, "IEN", 1, 30, 215, 0xeeddbb, 50);
        mFGI = new Register(this, "FGI", 1, 30, 255, 0xffccaa, 50);
        mFGO = new Register(this, "FGO", 1, 30, 295, 0xffbbaa, 50);

        // Create computer memory.
        mM = new Memory(this, 16, 4096, 450, 20, 0xddeeff);

        // Create assembler for this computer.
        mAssembler = new Assembler(this);
    }

    public function run():void {
        if (mAssembler.codes.length > 0) {
            if (mProgramLoaded) {
                while (mS.word == 1) {
                    nextInstruction();
                }
            } else {
                onError("Program must be loaded first. Assemble a program and press [Load].");
            }
        } else {
            onError("Program must be assembled first. Type a program and press [Assemble].");
        }
    }

    public function reset():void {
        mS.setWord(1);
        mI.reset();
        mE.reset();
        mR.reset();
        mIEN.reset();
        mFGI.reset();
        mFGO.reset();
        mAR.reset();
        mDR.reset();
        mAC.reset();
        mIR.reset();
        mTR.reset();
        mINPR.reset();
        mOUTR.reset();
        mM.reset();
        mSC.reset();
        mTicks = 0;
    }

    public function nextInstruction():void {
        // Check if computer has halted.
        if (mS.word == 0) {
            return;
        }

        switch (mSC.word) {
        case 0:
            if (mR.word == 0) {
                // == FETCH ==
                // -------------------------------------------------------------
                mSC.increment();

                // R'T0: AR <- PC
                mAR.setWord(mPC.word);
                onFinishCycle("R'T0: AR <- PC", "Fetch");
            }
            else {
                // == INTERRUPTION CYCLE ==
                // -------------------------------------------------------------
                mSC.increment();

                // RT0: AR <- 0
                mAR.reset();

                // RT0: TR <- PC
                mTR.setWord(mPC.word);
                onFinishCycle("RT0: AR <- 0 ; TR <- PC", "Interruption");
            }
            return;

        case 1:
            if (mR.word == 0) {
                mSC.increment();

                // R'T1: IR <- M[AR]
                mIR.setWord(mM.getWord(mAR.word));

                // R'T1: PC <- PC + 1
                mPC.increment();
                onFinishCycle("R'T1: IR <- M[AR] ; PC <- PC + 1", "Fetch");
            }
            else {
                mSC.increment();

                // RT1: M[AR] <- TR
                mM.setWord(mAR.word, mTR.word);

                // RT1: PC <- 0
                mPC.reset();
                onFinishCycle("RT1: M[AR] <- TR ; PC <- 0", "Interruption");
            }
            return;

        case 2:
            if (mR.word == 0) {
                // == DECODE ==
                // -------------------------------------------------------------
                mSC.increment();

                // R'T2: D0,...,D7: decode IR[12-14]
                mD = mIR.word & 0x7000;
                mD = 1 << (mD >> 12);

                // R'T2: AR <- IR[0-11]
                mAR.setWord(mIR.word & 0x0FFF);

                // R'T2: I <- IR[15]
                mI.setWord(mIR.word >> 15);
                onFinishCycle("R'T2: D0,...,D7: decode IR[12-14] ; AR <- IR[0-11] ; I <- IR[15]", "Decode");
            }
            else {
                // RT2: PC <- PC + 1
                mPC.increment();

                // RT2: IEN <- 0
                mIEN.reset();

                // RT2: R <- 0
                mR.reset();

                // RT2: SC <- 0
                mSC.reset();
                onFinishCycle("RT2: PC <- PC + 1 ; IEN <- 0 ; R <- 0 ; SC <- 0", "Interruption");
            }
            return;
        }

        // Check for interruption.
        if (mR.word == 0 && mIEN.word == 1 && (mFGI.word == 1 || mFGO.word == 1 )) {
            // T0'T1'T2'(IEN)(FGI + FGO): R <- 1
            mR.setWord(1);
            mParent.showMessage("T0'T1'T2'(IEN)(FGI + FGO): R <- 1");
            mParent.setDescription("Interruption ON");
            return;
        }

        // Check D(7) bit.
        if ((mD & 0x0080) == 0) {
            // == INDIRECT ADDRESS ==
            // -----------------------------------------------------------------
            if (mSC.word == 3) {
                mSC.increment();

                if (mI.word != 0) {
                    // D7'IT3: AR <- M[AR]
                    mAR.setWord(mM.getWord(mAR.word));
                    onFinishCycle("D7'IT3: AR <- M[AR]", "Indirect address");
                }
                else {
                    onFinishCycle("D7'I'T3: NOTHING", "Direct address");
                }
                return;
            }

            // == EXECUTE MEMORY REFERENCE INSTRUCTION ==
            // -----------------------------------------------------------------
            switch (mD) {
            case 0x0001:
                // AND
                // -------------------------------------------------------------
                switch (mSC.word) {
                case 4:
                    mSC.increment();

                    // D0T4: DR <- M[AR]
                    mDR.setWord(mM.getWord(mAR.word));
                    onFinishCycle("D0T4: DR <- M[AR]", "AND");
                    return;
                case 5:
                    // D0T5: AC <- AC & DR ; SC <- 0
                    mAC.setWord(mAC.word & mDR.word);
                    mSC.reset();
                    onFinishCycle("D0T5: AC <- AC & DR ; SC <- 0", "AND");
                    return;
                }
                break;
            case 0x0002:
                // ADD
                // -------------------------------------------------------------
                switch (mSC.word) {
                case 4:
                    mSC.increment();

                    // D1T4: DR <- M[AR]
                    mDR.setWord(mM.getWord(mAR.word));
                    onFinishCycle("D1T4: DR <- M[AR]", "ADD");
                    return;
                case 5:
                    // D1T5: AC <- AC + DR
                    mAC.setWord((mAC.word + mDR.word) & 0xFFFF);

                    // D1T5: E <- carry(AC) ; SC <- 0
                    mE.setWord((mAC.word + mDR.word) >> 16);
                    mSC.reset();
                    onFinishCycle("D1T5: AC <- AC + DR ; E <- carry(AC) ; SC <- 0", "ADD");
                    return;
                }
                break;
            case 0x0004:
                // LDA
                // -------------------------------------------------------------
                switch (mSC.word) {
                case 4:
                    mSC.increment();

                    // D2T4: DR <- M[AR]
                    mDR.setWord(mM.getWord(mAR.word));
                    onFinishCycle("D2T4: DR <- M[AR]", "LDA");
                    return;
                case 5:
                    // D2T5: AC <- DR ; SC <- 0
                    mAC.setWord(mDR.word);
                    mSC.reset();
                    onFinishCycle("D2T5: AC <- DR ; SC <- 0", "LDA");
                    return;
                }
                break;
            case 0x0008:
                // STA
                // -------------------------------------------------------------
                if (mSC.word == 4) {
                    // D3T4: M[AR] <- AC ; SC <- 0
                    mM.setWord(mAR.word, mAC.word);
                    mSC.reset();
                    onFinishCycle("D3T4: M[AR] <- AC ; SC <- 0", "STA");
                    return;
                }
                break;
            case 0x0010:
                // BUN
                // -------------------------------------------------------------
                if (mSC.word == 4) {
                    // D4T4: PC <- AR ; SC <- 0
                    mPC.setWord(mAR.word);
                    mSC.reset();
                    onFinishCycle("D4T4: PC <- AR ; SC <- 0", "BUN");
                    return;
                }
                break;
            case 0x0020:
                // BSA
                // -------------------------------------------------------------
                switch (mSC.word) {
                case 4:
                    mSC.increment();

                    // D5T4: M[AR] <- PC
                    mM.setWord(mAR.word, mPC.word);

                    // D5T4: AR <- AR + 1
                    mAR.increment();
                    onFinishCycle("D5T4: M[AR] <- PC ; AR <- AR + 1", "BSA");
                    return;
                case 5:
                    // D5T5: PC <- AR ; SC <- 0
                    mPC.setWord(mAR.word);
                    mSC.reset();
                    onFinishCycle("D5T5: PC <- AR ; SC <- 0", "BSA");
                    return;
                }
                break;
            case 0x0040:
                // ISZ
                // -------------------------------------------------------------
                switch (mSC.word) {
                case 4:
                    mSC.increment();
                    // D6T4: DR <- M[AR]
                    mDR.setWord(mM.getWord(mAR.word));
                    onFinishCycle("D6T4: DR <- M[AR]", "ISZ");
                    return;
                case 5:
                    mSC.increment();

                    // D6T5: DR <- DR + 1
                    mDR.increment();
                    onFinishCycle("D6T5: DR <- DR + 1", "ISZ");
                    return;
                case 6:
                    // D6T6: M[AR] <- DR
                    mM.setWord(mAR.word, mDR.word);

                    // D6T6: if (DR = 0) then (PC <- PC + 1) ; SC <- 0
                    if (mDR.word == 0) {
                        mPC.increment();
                    }
                    mSC.reset();
                    onFinishCycle("D6T6: M[AR] <- DR ; if (DR = 0) then (PC <- PC + 1) ; SC <- 0", "ISZ");
                    return;
                }
                break;
            default:
                onError("Unrecognized memory instruction:" + mD.toString(16));
            }
            onError("Wrong timing");
        }
        else if (mSC.word == 3) {
            if (mI.word == 0) {
                // == EXECUTE REGISTER REFERENCE INSTRUCTION ==
                // -------------------------------------------------------------
                // D7I'T3: r (true for all these instructions)
                // r: SC <- 0
                mSC.reset();

                // Bi = IR(i) ; i = {0,1,2,...,11}
                switch (mIR.word & 0x0FFF) {
                case 0x0800:
                    // CLEAR AC
                    // ---------------------------------------------------------
                    // CLA rB11: AC <- 0
                    mAC.reset();
                    onFinishCycle("D7I'T3B11: AC <- 0 ; SC <- 0", "CLA");
                    return;
                case 0x0400:
                    // CLEAR E
                    // ---------------------------------------------------------
                    // CLE rB10: E <- 0
                    mE.reset();
                    onFinishCycle("D7I'T3B10: E <- 0 ; SC <- 0", "CLE");
                    return;
                case 0x0200:
                    // COMPLEMENT AC
                    // ---------------------------------------------------------
                    // CMA rB9: AC <- complement(AC)
                    mAC.complement();
                    onFinishCycle("D7I'T3B9: AC <- complement(AC) ; SC <- 0", "CMA");
                    return;
                case 0x0100:
                    // COMPLEMENT E
                    // ---------------------------------------------------------
                    // CME rB8: E <- complement(E)
                    mE.complement();
                    onFinishCycle("D7I'T3B8: E <- complement(E) ; SC <- 0", "CME");
                    return;
                case 0x0080:
                    // RIGHT SHIFT
                    // ---------------------------------------------------------
                    // CIR rB7: AC <- shr(AC)
                    // CIR rB7: AC(15) <- E
                    // CIR rB7: E <- AC(0)
                    mE.setWord(mAC.rightShift(mE.word));
                    onFinishCycle("D7I'T3B7: AC <- shr(AC) ; AC(15) <- E ; E <- AC(0) ; SC <- 0", "CIR");
                    return;
                case 0x0040:
                    // LEFT SHIFT
                    // ---------------------------------------------------------
                    // CIL rB6: AC <- shl(AC)
                    // CIL rB6: AC(0) <- E
                    // CIL rB6: E <- AC(15)
                    mE.setWord(mAC.leftShift(mE.word));
                    onFinishCycle("D7I'T3B6: AC <- shl(AC) ; AC(0) <- E ; E <- AC(15)) ; SC <- 0", "CIL");
                    return;
                case 0x0020:
                    // INCREMENT AC
                    // ---------------------------------------------------------
                    // INC rB5: AC <- AC + 1
                    mAC.increment();
                    onFinishCycle("D7I'T3B5: AC <- AC + 1 ; SC <- 0", "INC");
                    return;
                case 0x0010:
                    // JUMP IF AC IS POSITIVE
                    // ---------------------------------------------------------
                    // SPA rB4: if (AC(15) = 0) then (PC <- PC + 1)
                    if ((mAC.word >> 15) == 0) {
                        mPC.increment();
                    }
                    onFinishCycle("D7I'T3B4: if (AC(15) = 0) then (PC <- PC + 1) ; SC <- 0", "SPA");
                    return;
                case 0x0008:
                    // JUMP IF AC IS NEGATIVE
                    // ---------------------------------------------------------
                    // SNA rB3: if (AC(15) = 1) then (PC <- PC + 1)
                    if ((mAC.word >> 15) == 1) {
                        mPC.increment();
                    }
                    onFinishCycle("D7I'T3B3: if (AC(15) = 1) then (PC <- PC + 1) ; SC <- 0", "SNA");
                    return;
                case 0x0004:
                    // JUMP IF AC IS ZERO
                    // ---------------------------------------------------------
                    // SZA rB2: if (AC = 0) then (PC <- PC + 1)
                    if (mAC.word == 0) {
                        mPC.increment();
                    }
                    onFinishCycle("D7I'T3B2: if (AC = 0) then (PC <- PC + 1) ; SC <- 0", "SZA");
                    return;
                case 0x0002:
                    // JUMP IF E IS ZERO
                    // ---------------------------------------------------------
                    // SZE rB1: if (E = 0) then (PC <- PC + 1)
                    if (mE.word == 0) {
                        mPC.increment();
                    }
                    onFinishCycle("D7I'T3B1: if (E = 0) then (PC <- PC + 1) ; SC <- 0", "SZE");
                    return;
                case 0x0001:
                    // HALT
                    // ---------------------------------------------------------
                    // HLT rB0: S <- 0
                    mS.reset();
                    onFinishCycle("D7I'T3B0: S <- 0 ; SC <- 0", "HLA");
                    onComputerHalted();
                    return;
                default:
                    onError("Unrecognized register instruction:" + mIR.word.toString(16));
                }
            }
            else {
                // == EXECUTE I/O INSTRUCTION ==
                // -------------------------------------------------------------
                // D7IT3: p (true for all these instructions)
                // p: SC <- 0
                mSC.reset();

                // Bi = IR(i) ; i = {6,7,8,9,10,11}
                switch (mIR.word & 0x0FFF) {
                case 0x0800:
                    // INP
                    // ---------------------------------------------------------
                    // pB11: AC(0-7) <- INPR
                    mAC.setWord(mINPR.word & 0x000F);

                    // pB11: FGI <- 0
                    mFGI.reset();

                    onFinishCycle("D7IT3B11: AC(0-7) <- INPR ; FGI <- 0 ; SC <- 0", "INP");
                    return;
                case 0x0400:
                    // OUT
                    // ---------------------------------------------------------
                    // pB10: OUTR <- AC(0-7)
                    mOUTR.setWord(mAC.word & 0x000F);

                    // pB10: FGO <- 0
                    mFGO.reset();
                    onFinishCycle("D7IT3B10: OUTR <- AC(0-7) ; FGO <- 0 ; SC <- 0", "OUT");
                    return;
                case 0x0200:
                    // SKI
                    // ---------------------------------------------------------
                    // pB9: if (FGI = 1) then (PC <- PC + 1)
                    if (mFGI.word == 1) {
                        mPC.increment();
                    }
                    onFinishCycle("D7IT3B9: if (FGI = 1) then (PC <- PC + 1) ; SC <- 0", "SKI");
                    return;
                case 0x0100:
                    // SKO
                    // ---------------------------------------------------------
                    // pB8: if (FGO = 1) then (PC <- PC + 1)
                    if (mFGO.word == 1) {
                        mPC.increment();
                    }
                    onFinishCycle("D7IT3B8: if (FGO = 1) then (PC <- PC + 1) ; SC <- 0", "SKO");
                    return;
                case 0x0080:
                    // ION
                    // ---------------------------------------------------------
                    // pB7: IEN <- 1
                    mIEN.setWord(1);
                    onFinishCycle("D7IT3B7: IEN <- 1 ; SC <- 0", "ION");
                    return;
                case 0x0040:
                    // IOF
                    // ---------------------------------------------------------
                    // pB6: IEN <- 0
                    mIEN.reset();
                    onFinishCycle("D7IT3B6: IEN <- 0 ; SC <- 0", "IOF");
                    return;
                default:
                    onError("Unrecognized I/O instruction:" + mIR.word.toString(16));
                }
            }
        }
    }

    private function onFinishCycle(message:String, instruction:String = ""):void {
        mParent.showMessage(message);
        mParent.setDescription(instruction);
        mParent.setCycles(++mTicks);
    }

    public function setMemoryUpperAddress(dir:String):void {
        var address:Number = Number(dir);
        if (address >= 0 && address < mM.words) {
            mM.setUpperAddress(address);
        }
        else { onError("Invalid RAM address: " + dir); }
    }

    public function setInpr(val:String):void {
        var value:Number = Number(val);
        if (value >= 0 && value < 256) {
            mINPR.setWord(value);
        }
        else { onError("Invalid value for INPR"); }
    }

    public function setFgo():void {
        mFGO.setWord(1);
    }

    public function setFgi():void {
        mFGI.setWord(1);
    }

    public function load():void {
        if (mAssembler.codes.length > 0) {
            // Clean registers and memory.
            reset();

            // At the beginning PC is loaded with the address of the program's first instruction.
            mPC.setWord(mAssembler.initAddress);

            // Load program in memory.
            for (var k:int = 0; k < mAssembler.codes.length; ++k) {
                mM.setWord(mAssembler.addresses[k], mAssembler.codes[k]);
            }
            mM.setUpperAddress(mAssembler.initAddress);
            mParent.setMemoryUpperAddress("0x" + mAssembler.initAddress.toString(16));

            mProgramLoaded = true;
            mParent.showMessage("Program was loaded. Press [RUN] to run the program or "
                                + "[NEXT] to go instruction by instruction");
        }
        else {
            onError("Program must be assembled first. Type a program and press [Assemble]");
        }
    }

    public function assemble(program:String):void {
        if (mAssembler.assemble(program)) {
            mParent.setAdressList(mAssembler.labels);
            mParent.showMessage("Program was successfuly assembled");
        }
    }

    public function onComputerHalted():void {
        mParent.showMessage("Computer halted");
    }

    public function onError(msg:String):void {
        msg = "[ERROR] " + msg;
        mParent.showMessage(msg);
    }
}
}
