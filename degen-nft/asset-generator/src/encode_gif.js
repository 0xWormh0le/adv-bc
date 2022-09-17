const fs = require('fs');
const pngFileStream = require('png-file-stream');
const GIFEncoder = require('gifencoder');
const path = require('path');


const imagesFolder = path.join(__dirname+'/../', 'zombie_frames')
// const imagesFolder = '/home/ubuntu/dev/canvas/nft-generator/gif_out/zombie'
// const imagesFolder = '/home/ubuntu/dev/canvas/nft-generator/gif_out/ZombieBG10'

const encoder = new GIFEncoder(900, 900);

function encodeGif() {
    // encoder.setDispose(1);
    pngFileStream(`${imagesFolder}/*.png`)
        .pipe(encoder.createWriteStream({ repeat: -1, delay: 0, quality: 30, dispose: 1 }))
        .pipe(fs.createWriteStream('myanimated.gif'));
}

encodeGif();
