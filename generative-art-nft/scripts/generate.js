const { execSync } = require('child_process')
const list = require('./result.json')
const { generate } = require('./lib')

const total = 10000
const characterCount = 5
const nftsPerOutfit = total / 50 / 4
const jobId = Number(process.argv[2])
const characters = list.slice(jobId * characterCount, jobId * characterCount + characterCount)
const headRelatedTraits = [
  'Eyes',
  'tattoo',
  'Hat',
  'Lower Face',
]

characters.forEach(({ name, data }) => {
  const traits = Object.keys(data).filter(trait => !['Outfit', 'Whole Head'].includes(trait))
  traits.sort(((a, b) => {
    if (a === 'Hat') {
      return 1
    } else if (b === 'Hat') {
      return -1
    } else {
      return 0
    }
  }))
  const traitsWithWholeHead = traits.filter(trait => !headRelatedTraits.includes(trait))
  const totalNftsPerOutfit = {}

  if (data['Whole Head']) {
    totalNftsPerOutfit.withWholeHead = traitsWithWholeHead.reduce((prev, trait) => prev * (data[trait].length + 1), data['Whole Head'].length)
  } else {
    totalNftsPerOutfit.withWholeHead = 0
  }

  totalNftsPerOutfit.withoutWholeHead = traits.reduce((prev, trait) => prev * (data[trait].length + 1), 1)

  const totalNftCountPerOutfit = totalNftsPerOutfit.withWholeHead + totalNftsPerOutfit.withoutWholeHead

  data.Outfit.forEach((outfit, key) => {
    const generated = []

    // execSync(`mkdir ../output/${name}/${outfit}`)

    for (let i = 0; i < nftsPerOutfit; i++) {
      while (true) {
        const index = Math.floor(Math.random() * totalNftCountPerOutfit)
        if (!generated.includes(index)) {
          generated.push(index)
          generate(name, data, outfit, key, index, totalNftsPerOutfit, traits, traitsWithWholeHead)
          break;
        }
      }
    }
  })
})
