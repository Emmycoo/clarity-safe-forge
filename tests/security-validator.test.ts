import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure contract validation works with valid contract ID",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const user1 = accounts.get("wallet_1")!;
    
    // First create a contract
    let block = chain.mineBlock([
      Tx.contractCall(
        "contract-factory",
        "create-contract",
        [types.uint(1)],
        user1.address
      )
    ]);
    
    // Then validate it
    block = chain.mineBlock([
      Tx.contractCall(
        "security-validator",
        "validate-contract",
        [types.uint(0)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    const result = block.receipts[0].result;
    result.expectOk().expectBool(true);
  },
});

Clarinet.test({
  name: "Ensure validation fails for invalid contract ID",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "security-validator", 
        "validate-contract",
        [types.uint(999)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    const result = block.receipts[0].result;
    result.expectErr().expectUint(201);
  },
});
