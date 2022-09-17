const { execSync } = require('child_process')

const index2TraitIndex = (index, traitLengthArray) => traitLengthArray.reduce(
  (prev, length) => ({
    result: prev.result.concat(prev.index % length),
    index: Math.floor(prev.index / length)
  }),
  { result: [], index }
).result

const callImagemagick = (name, characterName, outfit, traitIndex, traits, data) => {
  const basePath = `../data/${characterName.slice(0, 3)}`
  const background = `_Degen_Gang_${characterName.slice(0, 3)}_BG`
  const imagelist = [], staticTraits = [], animatedTrait = []

  const traitPath = name => {
    const index = traitIndex[traits[name]]
    if (index < data[name].length) {
      return data[name][index]
    } else {
      return null
    }
  }

  const bgEffectPath = traitPath('BG Effect')

  if (traits['BG Effect'] && bgEffectPath) {
    const bgEffect = `( ${basePath}/${background}/*.png null: ${basePath}/${characterName}/${bgEffectPath}/*.png -layers composite )`
    imagelist.push(`( ${bgEffect} null: ${basePath}/${characterName}/${outfit} -layers composite )`)
  } else {
    imagelist.push(`( ${basePath}/${background}/*.png null: ${basePath}/${characterName}/${outfit} -layers composite )`)
  }

  Object.keys(traits)
    .filter(trait => trait !== 'BG Effect')
    .forEach(trait => {
      const path = traitPath(trait)
      if (path) {
        if (path.endsWith('.png')) {
          staticTraits.push(`${basePath}/${characterName}/${path}`)
        } else {
          animatedTrait.push(`${basePath}/${characterName}/${path}/*.png`)
        }
      }
    })

  if (staticTraits.length) {
    imagelist.push(`( ${staticTraits.join(' ')} -background none -layers flatten )`)
  }

  if (animatedTrait.length) {
    imagelist.push(...animatedTrait)
  }

  const combined = imagelist.reduce(
    (prev, current, index) => {
      if (index < imagelist.length - 1) {
        return `( ${prev} null: ${current} -layers composite )`
      } else {
        return `( ${prev} null: ${current} -layers composite -layers optimizetransparency )`
      }
    }
  )

  const command = `..\\tools\\imagemagick\\convert -delay 4 -loop 0 ${combined} ${name}`
  console.log(command)
  // console.log('')
  // execSync(command)

  // .\tools\imagemagick\convert -delay 4 -loop 0 ( ( ( ( ./data/BOT/_Degen_Gang_BOT_BG/*.png null: ./data/BOT/BOT_1/Degen_Gang_BOT_1_OUTFIT_2_CASUAL.png -layers composite ) null: ( ./data/BOT/BOT_1/Degen_Gang_BOT_1_0009_MedMask.png ./data/BOT/BOT_1/Degen_Gang_BOT_1_0015_StarSticker.png ./data/BOT/BOT_1/Degen_Gang_BOT_1_0016_Bandaid.png -background none -layers flatten ) -layers composite ) null: ./data/BOT/BOT_1/Degen_Gang_BOT_1_0000_Anim_HAT_PropellerHAT/*.png -layers composite ) null: ./data/BOT/BOT_1/Degen_Gang_BOT_1_Anim_EYES/*.png -layers composite -layers optimizetransparency ) ./tmp.gif

  // .\tools\gifsicle\gifsicle -O3 --lossy=80 ./tmp.gif -o ./final.gif

}

const generate = (
  characterName,
  data,
  outfit,
  outfitIndex,
  index,
  totalNftsPerOutfit,
  traits,
  traitsWithWholeHead
) => {
  let traitsToBeUsed, traitList, traitMap = {}
  
  if (index < totalNftsPerOutfit.withoutWholeHead) {
    traitsToBeUsed = index2TraitIndex(index, traits.map(trait => data[trait].length + 1))
    traitList = traits
  } else {
    traitsToBeUsed = index2TraitIndex(index, traitsWithWholeHead.map(trait => data[trait].length + 1).concat(data['Whole Head'].length))
    traitList = trait.concat('Whole Head')
  }
  
  const name = `../output/${characterName}/${outfitIndex}/${characterName}-${outfitIndex}-${traitsToBeUsed.join('')}.gif`

  traitList.forEach((tl, i) => { traitMap[tl] = i })

  callImagemagick(name, characterName, outfit, traitsToBeUsed, traitMap, data)
}

module.exports = {
  generate,
}
