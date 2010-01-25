/* ========================================================================== */
/*   Memory.as                                                                */
/*   Copyright (c) 2010 Laurens Rodriguez Oscanoa.                            */
/* -------------------------------------------------------------------------- */
/*   This code is licensed under the MIT license:                             */
/*   http://www.opensource.org/licenses/mit-license.php                       */
/* -------------------------------------------------------------------------- */

package com.ex.comp {

import flash.display.Sprite;
import flash.utils.ByteArray;
import flash.display.DisplayObjectContainer;
import flash.text.TextField;
import flash.text.TextFormat;

public class Memory {
	
    private var mWords:int = 0;
    private var mBits:int = 0;
    private var mWordsInScreen:int = 0;
    private var mUpAddress:int = 0;
    private var mDownAddress:int = 0;
    private var mData:ByteArray = null;
    private var mCanvas:Sprite = null;
    private var mAddressLabels:Array = null;
    private var mHexDataLabels:Array = null;
    private var mDataLabels:Array = null;

    public function get graphic():Sprite { return mCanvas; }
    public function get words():int { return mWords; }

    public function Memory(parent:Computer,
                           bits:int,
                           words:int,
                           x:int = 0,
                           y:int = 0,
                           bodyColor:Number = 0xFFFFFF,
                           wordsInScren:int = 16,
                           borderSize:Number = 0.5,
                           nameColor:Number = 0xaa0000,
                           dataColor:Number = 0x000000,
                           hexDataColor:Number = 0x000099) {
        mWords = words;
        mBits = bits;
        mWordsInScreen = wordsInScren;
        mData = new ByteArray();
        mCanvas = new Sprite();

        var addressFormat:TextFormat = new TextFormat();
        addressFormat.font = "Courier";
        addressFormat.color = nameColor;
        addressFormat.size = 12;
        addressFormat.bold = true;

        var dataFormat:TextFormat = new TextFormat();
        dataFormat.font = "Courier";
        dataFormat.color = dataColor;
        dataFormat.size = 12;
        dataFormat.bold = true;

        var hexDataFormat:TextFormat = new TextFormat();
        hexDataFormat.font = "Courier";
        hexDataFormat.color = hexDataColor;
        hexDataFormat.size = 12;
        hexDataFormat.bold = true;

        var body:Sprite = new Sprite();
        body.graphics.lineStyle(borderSize, 0);
        body.graphics.beginFill(bodyColor);
        body.graphics.moveTo(0, 0);
        body.graphics.lineTo(0, 15 + 18 * mWordsInScreen);
        body.graphics.lineTo(25 + 12 * (mBits + 6), 15 + 18 * mWordsInScreen);
        body.graphics.lineTo(25 + 12 * (mBits + 6), 0);
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
        nameLabel.text = "RAM";
        nameLabel.x = 125;
        nameLabel.y = 5;
        mCanvas.addChild(nameLabel);

        mAddressLabels = new Array();
        mDataLabels = new Array();
        mHexDataLabels = new Array();

        for (var k:int = 0; k < mWordsInScreen; ++k) {
            var address:TextField = new TextField();
            address.selectable = false;
            address.defaultTextFormat = addressFormat;
            address.x = 15;
            address.y = 30 + 16 * k;
            mCanvas.addChild(address);
            mAddressLabels.push(address);

            var hexDataLabel:TextField = new TextField();
            hexDataLabel.selectable = false;
            hexDataLabel.defaultTextFormat = hexDataFormat;
            hexDataLabel.width = 4 * mBits;
            hexDataLabel.x = 52;
            hexDataLabel.y = 30 + 16 * k;
            mCanvas.addChild(hexDataLabel);
            mHexDataLabels.push(hexDataLabel);

            var dataLabel:TextField = new TextField();
            dataLabel.selectable = false;
            dataLabel.defaultTextFormat = dataFormat;
            dataLabel.width = 15 * mBits;
            dataLabel.x = 90;
            dataLabel.y = 30 + 16 * k;
            mCanvas.addChild(dataLabel);
            mDataLabels.push(dataLabel);
        }

        mCanvas.x = x;
        mCanvas.y = y;
        parent.addChild(mCanvas);

        reset();
    }

    public function getWord(address:int):uint {
        return ((mData[address * 2] << 8) | mData[address * 2 + 1]);
    }

    public function setWord(address:int, data:uint):void {
        mData.position = address * 2;
        mData.writeByte(data >> 8);
        mData.writeByte(data);
        updateData(address);
    }

    public function setUpperAddress(address:int):void {
        mUpAddress = address;
        mDownAddress = address + mWordsInScreen;
        for (var k:int = mUpAddress; k < mDownAddress; ++k) {
            updateData(k);
        }
    }

    public function reset():void {
        mData.clear();
        mData.length = mBits * mWords / 2;
        mUpAddress = 0;
        mDownAddress = mWordsInScreen;
        for (var k:int = 0; k < mDownAddress; ++k) {
            updateData(k);
        }
    }

    public function updateData(address:int):void {
        if (address >= mUpAddress && address < mDownAddress) {
            var data:uint = getWord(address);
            var index:int = address - mUpAddress;
            mAddressLabels[index].text = toHexString(address, 3);
            mHexDataLabels[index].text = toHexString(data, 4);
            mDataLabels[index].text = "";
            for (var k:int = mBits - 1; k >= 0; --k) {
                var bit:String = (data & (1 << k))? "1" : "0";
                mDataLabels[index].appendText(((k - 3) % 4)? bit : " " + bit);
            }
        }
    }

    private function toHexString(num:uint, width:int):String {
        if (num == 0) {
            return (width == 3)? "000" : "0000";
        }
        var ret:String = "";
        for (var k:int = 0; k < width; ++k) {
            var byte:int = (num & 0x000F);
            if (byte < 10) {
                ret = String(byte) + ret;
            } else  {
                ret = String.fromCharCode("A".charCodeAt() + byte - 10) + ret;
            }
            num >>= 4;
        }
        return ret;
    }
}
}

