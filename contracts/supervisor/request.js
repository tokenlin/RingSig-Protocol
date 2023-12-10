const { Contract } = require("ethers");
const fs = require("fs");
const path = require("path");
const { Location } = require("@chainlink/functions-toolkit");
require("@chainlink/env-enc").config();


const { signer } = require("../connection.js");
const { abi } = require("../contracts/abi/FunctionsConsumer.json");


// sepolia
const consumerAddress = "0xd207D1A041734F4b7e0EF0480Cf0Fa554d7787Fa"; 
const subscriptionId = "1759";




const sendRequest = async () => {
  if (!consumerAddress || !subscriptionId) {
    throw Error("Missing required environment variables.");
  }
  
  const functionsConsumer = new Contract(consumerAddress, abi, signer);

  const source = fs
    .readFileSync(path.resolve(__dirname, "../source.js"))
    .toString();

  
  // sepolia
  let args0 =           "0xacb01b8935a43fc31f32f3da8429732eac2aa73459e6a68c109b128c5f0b74f2";

  let args1 =           "0xC4bFccB1668d6E464F33a76baDD8C8D7D341e04A";  // balck list
  args1 = args1 + ";" + "0x85ACEF970c9Aa8252A8762eFc18d49892D79A712";


  let args2 = "0xC310a685b7Fc1FD3D9da18B58EF39cE57a56d4bC";  // address to receive award

  let args3 = "1";  // order index to report



  if(args3.length % 2 == 1) args3 = "0" + args3;  // require length even
  

  args1 = args1.toLocaleLowerCase();
  const args = [args0, args1, args2, args3];
  console.log(args);  

  const callbackGasLimit = 300_000;




  console.log("\n Sending the Request....")
  const requestTx = await functionsConsumer.sendRequest(
    source,
    // Location.DONHosted,
    // encryptedSecretsRef,
    args,
    [], // bytesArgs can be empty
    subscriptionId,
    callbackGasLimit
  );

  const txReceipt = await requestTx.wait(1);
  const requestId = txReceipt.events[2].args.id;
  console.log(
    `\nRequest made.  Request Id is ${requestId}. TxHash is ${requestTx.hash}`
  );
};

sendRequest().catch(err => {
  console.log("\nError making the Functions Request : ", err);
});
