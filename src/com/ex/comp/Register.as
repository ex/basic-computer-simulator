/* ========================================================================== */
/*   Register.as                                                              */
/*   Copyright (c) 2010 Laurens Rodriguez Oscanoa.                            */
/* -------------------------------------------------------------------------- */
/*   This code is licensed under the MIT license:                             */
/*   http://www.opensource.org/licenses/mit-license.php                       */
/* -------------------------------------------------------------------------- */

package com.ex.comp {

import flash.display.Sprite;
import flash.display.DisplayObjectContainer;
import flash.text.TextField;
import flash.text.TextFormat;

public class Register {
	
    private var mBits:int = 0;
    private var mName:String = null;
    private var mData:uint = 0;
    private var mMaxData:uint = 0;
    private var mLeftBit:uint = 0;
    private var mCanvas:Sprite = null;
    private var mParent:Computer = null;
    private var mDataLabel:TextField = null;

    public function get graphic():Sprite { return mCanvas; }
    public function get word():uint { return mData; }

    public function Register(parent:Computer,
                             name:String,
                             bits:int,
                             x:int = 0,
                             y:int = 0,
                             bodyColor:Number = 0xFFFFFF,
                             dataPadding:int = 30,
                             dataAligning:int = 0,
                             borderSize:Number = 0.5,
                             nameColor:Number = 0xaa0000,
                             dataColor:Number = 0x000000) {
        mBits = bits;
        mName = name;
        mParent = parent;
        mMaxData = (1 << mBits) - 1;
        mLeftBit = (1 << (mBits - 1));
        mCanvas = new Sprite();

        var body:Sprite = new Sprite();
        body.graphics.lineStyle(borderSize, 0);
        body.graphics.beginFill(bodyColor);
        body.graphics.moveTo(0, 0);
        body.graphics.lineTo(0, 30);
        body.graphics.lineTo(dataPadding + 13 * mBits, 30);
        body.graphics.lineTo(dataPadding + 13 * mBits, 0);
        body.graphics.lineTo(0, 0);
        body.graphics.endFill();
        mCanvas.addChild(body);

        var nameFormat:TextFormat = new TextFormat();
        nameFormat.font = "Verdana";
        nameFormat.color = nameColor;
        nameFormat.size = 14;
        nameFormat.bold = true;

        var nameLabel:TextField = new TextField();
        nameLabel.selectable = false;
        nameLabel.defaultTextFormat = nameFormat;
        nameLabel.text = mName;
        nameLabel.x = 7;
        nameLabel.y = 5;
        mCanvas.addChild(nameLabel);

        var dataFormat:TextFormat = new TextFormat();
        dataFormat.font = "Courier";
        dataFormat.color = dataColor;
        dataFormat.size = 12;
        dataFormat.bold = true;

        mDataLabel = new TextField();
        mDataLabel.selectable = false;
        mDataLabel.defaultTextFormat = dataFormat;
        mDataLabel.width = 15 * mBits;
        mDataLabel.x = dataPadding + dataAligning;
        mDataLabel.y = 7;
        mCanvas.addChild(mDataLabel);

        mCanvas.x = x;
        mCanvas.y = y;
        mParent.addChild(mCanvas);

        reset();
    }

    public function increment():void {
        if (mData < mMaxData) {
            mData = mData + 1;
        } else {
            mData = 0;
            mParent.onError("["+ mName + "]: overflow");
        }
        updateData();
    }

    public function reset():void {
        mData = 0;
        updateData();
    }

    public function complement():void {
        mData = (~mData & mMaxData);
        updateData();
    }

    public function rightShift(carry:uint):uint {
        var rBit:int = mData & 1;
        mData >>= 1;
        mData |= (carry << (mBits - 1));
        updateData();
        return rBit;
    }

    public function leftShift(carry:uint):uint {
        var lBit:int = (mData >> (mBits - 1));
        mData <<= 1;
        mData |= carry;
        updateData();
        return lBit;
    }

    public function setWord(data:uint):void {
        mData = data & mMaxData;
        updateData();
    }

    public function updateData():void {
        mDataLabel.text = "";
        for (var k:int = mBits - 1; k >= 0; --k) {
            var bit:String = (mData & (1 << k))? "1" : "0";
            mDataLabel.appendText(((k - 3) % 4)? bit : " " + bit);
        }
    }
}
}
