const { expect } = require('chai')
const { ethers } = require("hardhat")
const { BigNumber } = require('ethers')
const { sign, privateKey } = require('./signer')


describe('DegenNFT', () => {
  before(async () => {
    const users = await ethers.getSigners()

    users.forEach((user, index) => {
      user.privateKey = privateKey(index)
    })

    this.users = users.slice(1)
    this.owner = users[0]

    const DegenToken = await ethers.getContractFactory('DegenToken')
    const DegenNFT = await ethers.getContractFactory('DegenNFT')

    this.degenToken = await DegenToken.deploy('Degen', 'Degen', 1000)
    this.degenNft = await DegenNFT.deploy('DegenNFT', 'DegenNFT', this.degenToken.address)
  })

  describe('Attribute', () => {
    describe('add attr', () => {
      it('addAttr fails: invalid attr name', async () => {
        await expect(this.degenNft.connect(this.owner).addAttr(
          '',
          ['https://degenattr.com/bot1-head-anim', 0, 0]
        )).to.revertedWith('DegenNFT: invalid attr name')
      })

      it('addAttr fails: invalid attr uri', async () => {
        await expect(this.degenNft.connect(this.owner).addAttr(
          'bot1-head-anim',
          ['', 0, 0]
        )).to.revertedWith('DegenNFT: invalid attr uri')
      })

      it('addAttr fails: not owner', async () => {
        const [alice] = this.users
        await expect(this.degenNft.connect(alice).addAttr(
          'bot1-head-anim',
          ['https://degenattr.com/bot1-head-anim', 0, 0]
        )).to.revertedWith('Ownable: caller is not the owner')
      })

      it('addAttr succeeds', async () => {
        await expect(this.degenNft.connect(this.owner).addAttr(
          'bot1-head-anim',
          ['https://degenattr.com/bot1-head-anim', 0, 0]
        )).to.emit(this.degenNft, 'AttrAdded')
          .withArgs(
            this.owner.address,
            'bot1-head-anim',
            [
              'https://degenattr.com/bot1-head-anim',
              BigNumber.from(0),
              BigNumber.from(0)
            ]
          )

        expect(await this.degenNft.attrs('bot1-head-anim'))
          .to.eql([
            'https://degenattr.com/bot1-head-anim',
            BigNumber.from(0),
            BigNumber.from(0)
          ])
      })

      it('addAttr fails: attr duplicated', async () => {
        await expect(this.degenNft.connect(this.owner).addAttr(
          'bot1-head-anim',
          ['https://degenattr.com/bot1-head-anim', 0, 0]
        )).to.revertedWith('DegenNFT: attr duplicated')
      })

      it('addAttr succeeds for another attr', async () => {
        await expect(this.degenNft.connect(this.owner).addAttr(
          'bot1-body-anim',
          ['https://degenattr.com/bot1-body-anim', 0, 1]
        )).to.emit(this.degenNft, 'AttrAdded')
          .withArgs(
            this.owner.address,
            'bot1-body-anim',
            [
              'https://degenattr.com/bot1-body-anim',
              BigNumber.from(0),
              BigNumber.from(1)
            ]
          )

        expect(await this.degenNft.attrs('bot1-body-anim'))
          .to.eql([
            'https://degenattr.com/bot1-body-anim',
            BigNumber.from(0),
            BigNumber.from(1)
          ])
      })
    })

    describe('add attr to token', () => {
      before(async () => {
        const [alice] = this.users
        const { r: r1, s: s1, v: v1 } = sign(alice.privateKey, 10, 0, 'bot1-head-anim', 'bot1-body-anim')
        const { r: r2, s: s2, v: v2 } = sign(alice.privateKey, 20, 0, 'bot1-head-anim')

        await this.degenNft.connect(this.owner).purchase(
          alice.address,
          10,
          0,
          ['bot1-head-anim', 'bot1-body-anim'],
          v1,
          r1,
          s1
        )

        await this.degenNft.connect(this.owner).purchase(
          alice.address,
          20,
          0,
          ['bot1-head-anim'],
          v2,
          r2,
          s2
        )
      })

      it('addTokenAttr fails: add attr to non-minted token', async () => {
        await expect(this.degenNft.connect(this.owner).addTokenAttr(2, 'bot1-head-anim'))
          .to.revertedWith('DegenNFT: token not minted')
      })

      it('addTokenAttr fails: invalid attr name', async () => {
        await expect(this.degenNft.connect(this.owner).addTokenAttr(0, 'bot1-eye-anim'))
          .to.revertedWith('DegenNFT: invalid attr name')
      })

      it('addTokenAttr fails: not owner', async () => {
        const [alice] = this.users
        await expect(this.degenNft.connect(alice).addTokenAttr(0, 'bot1-head-anim'))
          .to.revertedWith('Ownable: caller is not the owner')
      })

      it('addTokenAttr fails: attr duplicated', async () => {
        await expect(this.degenNft.connect(this.owner).addTokenAttr(0, 'bot1-head-anim'))
          .to.revertedWith('DegenNFT: attr duplicated')
      })

      it('addTokenAttr succeeds', async () => {
        await expect(this.degenNft.connect(this.owner).addTokenAttr(1, 'bot1-body-anim'))
          .to.emit(this.degenNft, 'AttrAddedToToken')
          .withArgs(this.owner.address, 1, 'bot1-body-anim')

        expect(await this.degenNft.tokenAttrNames(1))
          .to.eql(['bot1-head-anim', 'bot1-body-anim'])
      })

      it('tokenDetails', async () => {
        expect(await this.degenNft.tokenDetails(0))
          .to.eql([
            BigNumber.from(0),
            ['bot1-head-anim', 'bot1-body-anim'],
            [
              ['https://degenattr.com/bot1-head-anim', BigNumber.from(0), BigNumber.from(0)],
              ['https://degenattr.com/bot1-body-anim', BigNumber.from(0), BigNumber.from(1)]
            ]
          ])
      })
    })

    describe('remove attr from token', () => {
      it('removeTokenAttr fails: remove attr from non-minted token', async () => {
        await expect(this.degenNft.connect(this.owner).removeTokenAttr(2, 'bot1-head-anim'))
          .to.revertedWith('DegenNFT: token not minted')
      })

      it('removeTokenAttr fails: not owner', async () => {
        const [alice] = this.users
        await expect(this.degenNft.connect(alice).removeTokenAttr(1, 'bot1-head-anim'))
          .to.revertedWith('Ownable: caller is not the owner')
      })

      it('removeTokenAttr fails: attr not found', async () => {
        await expect(this.degenNft.connect(this.owner).removeTokenAttr(1, 'bot1-eye-anim'))
          .to.revertedWith('DegenNFT: attr not found')
      })

      it('removeTokenAttr succeeds', async () => {
        await expect(this.degenNft.connect(this.owner).removeTokenAttr(1, 'bot1-head-anim'))
          .to.emit(this.degenNft, 'AttrRemovedFromToken')
          .withArgs(this.owner.address, 1, 'bot1-head-anim')

        expect(await this.degenNft.tokenAttrNames(1))
          .to.eql(['bot1-body-anim'])
      })
    })

    describe('transfer attr', () => {
      it('transferAttr fails: source token not minted', async () => {
        await expect(this.degenNft.connect(this.owner).transferAttr(2, 1, 'bot1-body-anim'))
          .to.revertedWith('DegenNFT: token not minted')
      })

      it('transferAttr fails: dest token not minted', async () => {
        await expect(this.degenNft.connect(this.owner).transferAttr(0, 2, 'bot1-body-anim'))
          .to.revertedWith('DegenNFT: token not minted')
      })

      it('transferAttr fails: not owner', async () => {
        const [alice] = this.users
        await expect(this.degenNft.connect(alice).transferAttr(0, 1, 'bot1-body-anim'))
          .to.revertedWith('Ownable: caller is not the owner')
      })

      it('transferAttr fails: attr not found in source token', async () => {
        await expect(this.degenNft.connect(this.owner).transferAttr(0, 1, 'bot1-eye-anim'))
          .to.revertedWith('DegenNFT: attr not found')
      })

      it('transferAttr fails: attr duplicated in source token', async () => {
        await expect(this.degenNft.connect(this.owner).transferAttr(0, 1, 'bot1-body-anim'))
          .to.revertedWith('DegenNFT: attr duplicated')
      })

      it('transferAttr succeeds', async () => {
        await expect(this.degenNft.connect(this.owner).transferAttr(0, 1, 'bot1-head-anim'))
          .to.emit(this.degenNft, 'AttrTransferred')
          .withArgs(this.owner.address, 0, 1, 'bot1-head-anim')

        expect(await this.degenNft.tokenAttrNames(0))
          .to.eql(['bot1-body-anim'])

        expect(await this.degenNft.tokenAttrNames(1))
          .to.eql(['bot1-body-anim', 'bot1-head-anim'])
      })
    })
  })

  describe('Purchase', () => {
    it('purchase fails: not owner', async () => {
      const [alice] = this.users
      const { r, s, v } = sign(alice.privateKey, 10, 0, 'head')

      await expect(this.degenNft.connect(alice).purchase(
        alice.address,
        10,
        0,
        ['head'],
        v,
        r,
        s
      )).to.revertedWith('Ownable: caller is not the owner')
    })

    it('purchase fails: invalid signature', async () => {
      const [alice] = this.users
      const { r, s, v } = sign(alice.privateKey, 10, 0, 'bot1-head-anim')

      await expect(this.degenNft.connect(this.owner).purchase(
        this.owner.address,
        10,
        0,
        ['bot1-head-anim'],
        v,
        r,
        s
      )).to.revertedWith('DegenNFT: invalid signature')

      await expect(this.degenNft.connect(this.owner).purchase(
        alice.address,
        10,
        0,
        ['bot1-head-anim', 'bot1-body-anim'],
        v,
        r,
        s
      )).to.revertedWith('DegenNFT: invalid signature')
    })

    it('purchase fails: invalid attr name', async () => {
      const [alice] = this.users
      const { r, s, v } = sign(alice.privateKey, 10, 0, 'bot1-eye-anim')

      await expect(this.degenNft.connect(this.owner).purchase(
        alice.address,
        10,
        0,
        ['bot1-eye-anim'],
        v,
        r,
        s
      )).to.revertedWith('DegenNFT: invalid attr name')
    })

    it('purchase succeeds', async () => {
      const [alice] = this.users
      const { r, s, v } = sign(alice.privateKey, 10, 0, 'bot1-head-anim', 'bot1-body-anim')

      await expect(this.degenNft.connect(this.owner).purchase(
        alice.address,
        10,
        0,
        ['bot1-head-anim', 'bot1-body-anim'],
        v,
        r,
        s
      )).to.emit(this.degenNft, 'TokenPurchased')
        .withArgs(this.owner.address, alice.address, 10, 0, ['bot1-head-anim', 'bot1-body-anim'], 2)

      expect(await this.degenNft.tokenAttrNames(2))
        .to.eql(['bot1-head-anim', 'bot1-body-anim'])
    })
  })
})
