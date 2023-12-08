require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity:{
          compilers:[
              {version:"0.5.16"},
              {version:"0.7.6"},
              {version:"0.8.0"},
              {version:"0.8.20"}
          ]
  },


  // networks: {
  //     hardhat: {
  //       // 添加 forking 内容
  //       forking: {
  //         url: "https://mainnet.infura.io/v3/b0cc7ee385d64182a49eec2312619831",
  //         // 如果不指定区块，则默认 fork 当前最新区块
  //         // blockNumber: 18280860
  //       }
  //     }
  //   }
};
