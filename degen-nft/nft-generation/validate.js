const fs = require('fs')
const list = require('./result.json')

const dataPath = '../data/'
const missing = []

list.slice(0, 5).forEach(({ name, data }) => {
  for (const trait in data) {
    data[trait].forEach(file => {
      const path = `${dataPath}${name.slice(0, 3)}/${name}/${file}`
      if (!fs.existsSync(path)) {
        missing.push({ name, path })
      }
    })
  }
})

console.log(missing)
