from web3 import Web3
import json
import time
import csv


# mudar rpc e contract address
rpc_url = 'http://localhost:8545/'
contract_address = ''

#mudar o abi (pegar do remix na aba compile)
contract_abi = '''
'''

#mudar o private key e o account address (pegar do metamask)
private_key = ''
account_address = ''  
# Connect to the blockchain
w3 = Web3(Web3.HTTPProvider(rpc_url))

# Check if connection is successful
if w3.is_connected():
    print("Connected to blockchain.")
else:
    print("Failed to connect to blockchain.")


# Load the smart contract
contract = w3.eth.contract(address=contract_address, abi=contract_abi)
# Create a transaction


transaction_input = b''


def cast_vote(id = 1, support = transaction_input):
    nonce = w3.eth.get_transaction_count(account_address)
    #mudar o metodo createTransaction para o metodo do contrato e tbm adicionar os parametros na mesma ordem do contrato
    transaction = contract.functions.Cast_Vote(id, support).build_transaction({
        #alterar o chainId para o da rede que esta usando
        'chainId': 9000,  
        'gas': 9000000,
        'gasPrice': w3.to_wei('500', 'gwei'),
        'nonce': nonce,
        'from': account_address  # Specify the sender account
    })
    signed_tx = w3.eth.account.sign_transaction(transaction, private_key)
    tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)

    return tx_hash.hex()



# Get transaction count
def get_transaction_count():
    count = contract.functions.getTransactionCount().call()
    return count

# Get a transaction by index
def get_transaction_by_index(index):
    transaction = contract.functions.getTransaction(index).call()
    return transaction


def get_proposal(id):
    transaction = contract.functions.variables(id).call()
    return transaction



# Example usage
# Record transaction details in a CSV file
csv_file = 'cast_vote.csv'
results = []

for _ in range(1000):
    start_time = time.perf_counter()
    tx_hash = cast_vote()
    w3.eth.wait_for_transaction_receipt(tx_hash)
    execution_time = time.perf_counter() - start_time
    results.append({"Execution time": execution_time, "Tx hash": tx_hash})

with open(csv_file, mode='w', newline='') as file:
    writer = csv.DictWriter(file, fieldnames=["Execution time", "Tx hash"])
    writer.writeheader()
    for result in results:
        writer.writerow(result)

print(f"Transaction details have been recorded in {csv_file}")

