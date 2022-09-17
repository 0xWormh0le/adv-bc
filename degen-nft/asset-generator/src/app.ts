import mergeImages from 'merge-images';
import  { createCanvas, Canvas, Image } from 'canvas';
import fs from 'fs';
import gifFrames from 'gif-frames';
import pngFileStream from 'png-file-stream';
// import GIFEncoder from 'gifencoder';
import GIFEncoder from 'gif-encoder-2';
import { createWriteStream, readdir } from 'fs';
import { promisify } from 'util';
import path from 'path';


const readdirAsync = promisify(readdir)
const imagesFolder = path.join(__dirname+'/../', 'input')
// const imagesFolder = '/home/ubuntu/dev/canvas/nft-generator/gif_out/zombie'
// const imagesFolder = '/home/ubuntu/dev/canvas/nft-generator/gif_out/ZombieBG10'

// const encoder = new GIFEncoder(900, 900);
// const encoder = new GIFEncoder(900, 900, 'neuquant', true, 20);


const BASE_TOTAL_COUNT = 1;
const CLOTHES_TOTAL_COUNT = 3;
const PROPERTY_TOTAL_COUNT = 6;
const ZOMBIE_OUT_PATH = 'zombies/';

const zombieFolder = ['Zombie01', 'Zombie02', 'Zombie03', 'Zombie04', 'Zombie05'];
const zombieFile = ['zombie01', 'zombie02', 'zombie03', 'zombie04', 'zombie05'];

const ZOMBIE_TOTAL_COUNT = 5;

// for (let zIndex = 0; zIndex < ZOMBIE_TOTAL_COUNT; zIndex++) {
//     mergeImages([
//         { src: `asset/${zombieFolder[zIndex]}/${zombieFile[zIndex]}_0009_Base.png`, x: 0, y: 0 },
//         { src: `asset/${zombieFolder[zIndex]}/${zombieFile[zIndex]}_0002_LaserEyes.png`, x: 0, y: 0 },
//         { src: `asset/${zombieFolder[zIndex]}/${zombieFile[zIndex]}_0003_Cigarette.png`, x: 0, y: 0 },
//         { src: `asset/${zombieFolder[zIndex]}/${zombieFile[zIndex]}_0004_Hat.png`, x: 0, y: 0 },
//         { src: `asset/${zombieFolder[zIndex]}/${zombieFile[zIndex]}_0005_Headphones.png`, x: 0, y: 0 },
//         { src: `asset/${zombieFolder[zIndex]}/${zombieFile[zIndex]}_0006_Battle.png`, x: 0, y: 0 },
//         { src: `asset/${zombieFolder[zIndex]}/${zombieFile[zIndex]}_0007_Casual.png`, x: 0, y: 0 },
//         { src: `asset/${zombieFolder[zIndex]}/${zombieFile[zIndex]}_0008_Fancy.png`, x: 0, y: 0 },
//         { src: `asset/${zombieFolder[zIndex]}/${zombieFile[zIndex]}_0000_RHand.png`, x: 0, y: 0 },
//         { src: `asset/${zombieFolder[zIndex]}/${zombieFile[zIndex]}_0001_LHand.png`, x: 0, y: 0 },
//       ], {Canvas: Canvas, Image: Image}).then(b64 => {
//         const base64Data = b64.replace(/^data:image\/png;base64,/,"");
//         const binaryData = Buffer.from(base64Data, 'base64').toString('binary');
//             console.log("OKOK")
//             fs.writeFile(`${zombieFolder[zIndex]}.png`, binaryData, 'binary', function(err) {
//                 console.log(err)
//             });
//         })
//         .catch(err => console.log(err));
// }

// async function createGif(algorithm) {
//     return new Promise(async resolve1 => {
//       // read image directory
//       const files = await readdirAsync(imagesFolder)
  
//       // find the width and height of the image
//       const [width, height] = await new Promise(resolve2 => {
//         const image = new Image()
//         image.onload = () => resolve2([image.width, image.height])
//         image.src = path.join(imagesFolder, files[0])
//       })
  
//       // base GIF filepath on which algorithm is being used
//       const dstPath = path.join(imagesFolder, 'output', `intermediate-${algorithm}.gif`)
//       // create a write stream for GIF data
//       const writeStream = createWriteStream(dstPath)
//       // when stream closes GIF is created so resolve promise
//       writeStream.on('close', () => {
//         resolve1(0)
//       })
  
//       const encoder = new GIFEncoder(width, height, algorithm, true)
//       // pipe encoder's read stream to our write stream
//       encoder.createReadStream().pipe(writeStream)
//       encoder.start()
//       encoder.setDelay(0)
//       encoder.setThreshold(20)
  
//       const canvas = createCanvas(width, height)
//       const ctx = canvas.getContext('2d')
  
//       // draw an image for each file and add frame to encoder
//       for (const file of files) {
//         await new Promise(resolve3 => {
//           const image = new Image()
//           image.onload = () => {
//             ctx.drawImage(image, 0, 0)
//             encoder.addFrame(ctx)
//             resolve3(0)
//           }
//           image.src = path.join(imagesFolder, file)
//         })
//       }
//     })
//   }
  
//   createGif('neuquant')
//   createGif('octree')

// function encodeGif() {
//     // encoder.setDispose(1);
//     // pngFileStream('gif_out/ZombieBG10/*.png')
//     pngFileStream('gif_out/zombie/*.png')
//         .pipe(encoder.createWriteStream({ repeat: -1, delay: 0, quality: 30, dispose: 1 }))
//         .pipe(fs.createWriteStream('myanimated.gif'));
// }

// encodeGif();

// function decodeGif() {
//     gifFrames({ url: 'asset/BG/ZombieBG01.gif', frames: 'all', cumulative: false, outputType: 'png' }).then(function (frameData) {
//         console.log(frameData.length);
//         for (let i = 0; i < frameData.length; i++) {
//             frameData[i].getImage().pipe(fs.createWriteStream(`frame${i}.png`));
//         }
        
//       });
// }

// decodeGif();

function generateImageArray(zombieNumber, propertyNumber, clothesNumber) {
    const rHand = propertyNumber >> 5;
    const lHand = (propertyNumber >> 4) % 2;
    const eyes = (propertyNumber >> 3) % 2;
    const cigar = (propertyNumber >> 2) % 2;
    const hat = (propertyNumber >> 1) % 2;
    const phone = propertyNumber % 2;

    let imageArray = [];
    const clothesString = ['0006_Battle', '0007_Casual', '0008_Fancy']
    
    imageArray.push({ src: `asset/${zombieFolder[zombieNumber]}/${zombieFile[zombieNumber]}_0009_Base.png`, x: 0, y: 0 });
    
    if (eyes) {
        imageArray.push({ src: `asset/${zombieFolder[zombieNumber]}/${zombieFile[zombieNumber]}_0002_LaserEyes.png`, x: 0, y: 0 });
    }
    if (cigar) {
        imageArray.push({ src: `asset/${zombieFolder[zombieNumber]}/${zombieFile[zombieNumber]}_0003_Cigarette.png`, x: 0, y: 0 });
    }
    if (hat) {
        imageArray.push({ src: `asset/${zombieFolder[zombieNumber]}/${zombieFile[zombieNumber]}_0004_Hat.png`, x: 0, y: 0 });
    }
    if (phone) {
        imageArray.push({ src: `asset/${zombieFolder[zombieNumber]}/${zombieFile[zombieNumber]}_0005_Headphones.png`, x: 0, y: 0 });
    }

    if (clothesNumber > 0) {
        imageArray.push({ src: `asset/${zombieFolder[zombieNumber]}/${zombieFile[zombieNumber]}_${clothesString[clothesNumber-1]}.png`, x: 0, y: 0 });
    }

    if (rHand) {
        imageArray.push({ src: `asset/${zombieFolder[zombieNumber]}/${zombieFile[zombieNumber]}_0000_RHand.png`, x: 0, y: 0 });
    }
    if (lHand) {
        imageArray.push({ src: `asset/${zombieFolder[zombieNumber]}/${zombieFile[zombieNumber]}_0001_LHand.png`, x: 0, y: 0 });
    }

    let fileName = `${ZOMBIE_OUT_PATH}Zombie0${zombieNumber+1}/${rHand}${lHand}${eyes}${cigar}${hat}${phone}${clothesNumber}.png`;
    return {imageArray, fileName};
}

function generateZombies() {
    for (let zIndex = 0; zIndex < ZOMBIE_TOTAL_COUNT; zIndex ++) {
        for (let bIndex = 0; bIndex < BASE_TOTAL_COUNT; bIndex++) {
            for (let cIndex = 0; cIndex <= CLOTHES_TOTAL_COUNT; cIndex++) {
                // for (let pIndex = 0; pIndex < 2 ** PROPERTY_TOTAL_COUNT; pIndex++) {
                for (let pIndex = 0; pIndex < 2; pIndex++) {
                    const {imageArray, fileName} = generateImageArray(zIndex, pIndex, cIndex);
                    console.log(imageArray);
                    console.log(fileName);
                    
                    mergeImages(imageArray, {Canvas: Canvas, Image: Image}).then(b64 => {
                                const base64Data = b64.replace(/^data:image\/png;base64,/,"");
                                const binaryData = Buffer.from(base64Data, 'base64').toString('binary');
                                    fs.writeFile(fileName, binaryData, 'binary', function(err) {
                                        if (!err) {
                                            console.log(`${fileName} Success`);
                                        } else {
                                            console.log(`${fileName} failed`);
                                        }
                                    });
                                })
                                .catch(err => console.log(err));
                }
            }
        }    
    }
    
}

generateZombies();
