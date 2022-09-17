const fs = require('fs')

let prevCharacter = null
let character = {}
const result = []
const anims = []

const data = fs.readFileSync('./assets.txt', 'utf8')
const lines = data.split('\r\n')

lines.forEach((line, index) => {
  const [ characterName, trait, file ] = line.split('\t')
  if (characterName !== prevCharacter) {
    result.push({
      name: prevCharacter,
      data: character
    })
    character = {}
  }
  prevCharacter = characterName
  
  if (!character[trait]) {
    character[trait] = [file]
  } else {
    character[trait].push(file)
  }

  if (file) {
    const pos = file.indexOf('Anim')
    if (pos >= 0) {
      const anim = file.slice(pos)
      if (!anims.includes(anim)) {
        anims.push(anim)
      }
    }
  }
})

console.log(anims)
// fs.writeFileSync('./result.json', JSON.stringify(result))
