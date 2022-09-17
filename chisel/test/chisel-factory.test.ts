import { expect } from 'chai';

import { runTestSuite } from '../helpers/lib';
import { TestVars } from '../helpers/types';

runTestSuite('ChiselFactory', (vars: TestVars) => {
  it('check chisel implementaion', async () => {
    const { Chisel, ChiselFactory } = vars;

    expect(await ChiselFactory.chiselImpl()).to.equal(Chisel.address);
  });

  it('update chisel implementation', async () => {
    const {
      Chisel,
      ChiselFactory,
      namedAccounts: { admin },
    } = vars;

    await ChiselFactory.connect(admin.signer).updateChiselImpl(Chisel.address);
    expect(await ChiselFactory.chiselImpl()).to.equal(Chisel.address);
  });

  it('create chisel', async () => {
    const {
      ChiselFactory,
      Vault,
      BaseTokenMock,
      namedAccounts: { admin },
    } = vars;

    await expect(ChiselFactory.allChisels(0)).to.revertedWith('');

    await expect(
      ChiselFactory.connect(admin.signer).createChisel(
        admin.address,
        Vault.address,
        BaseTokenMock.address
      )
    ).to.emit(ChiselFactory, 'NewChisel');

    await ChiselFactory.allChisels(0);
  });
});
