const fs = require('fs');
const gifFrames = require('gif-frames');
const path = require('path');

const imagesFolder = path.join(__dirname+'/../', 'zombie_frames')
console.log(imagesFolder)

function decodeGif() {
    gifFrames({ url: 'asset/BG/ZombieBG01.gif', frames: 'all', cumulative: false, outputType: 'png' }).then(function (frameData) {
        console.log(frameData.length);
        for (let i = 0; i < frameData.length; i++) {
            frameData[i].getImage().pipe(fs.createWriteStream(`zombie_frames/frame${i}.png`));
        }
        
      });
}

decodeGif();
