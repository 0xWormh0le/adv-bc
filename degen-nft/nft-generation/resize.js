const fs = require('fs')
const { execSync } = require('child_process')
const list = require('./result.json')

const size = 400
const dataPath = '../data/'
const groups = [
  'BOT',
  'BST',
  'CLN',
  'CLT',
  'COV',
  'DMN',
  'HOD',
  'ROY',
  'WHA',
  'ZOM',
]

const resize = (file, size) => {
  execSync(`..\\tools\\imagemagick\\convert ${file} -resize ${size}x${size} ${file}`)
}

const printTime = () => {
  console.log(new Date().toString())
}

list.forEach(({ name, data }, index) => {
  printTime()
  console.log(`Resizing traits: ${index} / ${list.length} characters`)
  for (const trait in data) {
    data[trait].forEach(file => {
      const path = `${dataPath}${name.slice(0, 3)}/${name}/${file}`
      if (path.endsWith('.png')) {
        resize(path, size)
      } else {
        fs.readdirSync(path).forEach(file => resize(`${path}/${file}`, size))
      }
    })
  }
})

groups.forEach((group, index) => {
  printTime()
  console.log(`Resizing backgrounds: ${index} / ${list.length}`)
  const path = `${dataPath}${group}/_Degen_Gang_${group}_BG`
  fs.readdirSync(path).forEach(file => resize(`${path}/${file}`, size))
})
