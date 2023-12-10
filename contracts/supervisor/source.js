
const txArray = args[0].split(";");
const addressInputArray = args[1].split(";");
const awardReceiver = args[2];
const orderIndex = args[3];


if(txArray.length < 1) throw Error("txArray length should be not less than 1");
if(addressInputArray.length < 2) throw Error("addressInputArray length should be not less than 2");

let addressFromTxArray=[];
for(let i=0; i<txArray.length; i++) {
  const apiResponse = await Functions.makeHttpRequest({
    url: `https://api-sepolia.etherscan.io/api`,
    headers: {
      "Content-Type": "application/json",
    },
    
    params: {
      module: "proxy",
      action: "eth_getTransactionByHash",
      txhash: txArray[i],
      apikey: "YOUR API KEY",  // replace your apikey
    },
  });
  
  if (apiResponse.error) {
    console.error(apiResponse.error);
    throw Error("Request failed");
  }
  const { data } = apiResponse;
  
  const _from = data.result.from;
  const _to = data.result.to;


  if(_from == undefined) throw Error("Data error: undefined");
  if(_from == NaN) throw Error("Data error: NaN");
  if(_from == "") throw Error("Data error: empty");

  addressFromTxArray.push(_from);
  addressFromTxArray.push(_to);

}

if(addressFromTxArray.length !== txArray.length * 2) throw Error("addressFromTxArray push error");

for(let i=0; i<addressFromTxArray.length; i++){
  let checkResult = false;
  for(let j=0; j<addressInputArray.length; j++){
    if(addressFromTxArray[i] == addressInputArray[j]) checkResult = true;
  }
  if(checkResult == false) throw Error("Addresslist input is not correct!");
}

const stringReturn = addressInputArray[0] + addressInputArray[addressInputArray.length-1] + awardReceiver + orderIndex;

console.log(stringReturn);
return Functions.encodeString(stringReturn);
