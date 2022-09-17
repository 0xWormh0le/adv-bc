import { ethers } from 'hardhat';
import { Sample__factory, Sample } from '../typechain';

describe('Sample Test', async () => {
    it('Deploy', async () => {
        let [account1, account2] = await ethers.getSigners();
        let sample = await (await new Sample__factory(account1)).deploy();
        console.log({sample: sample.address})
    });
});
