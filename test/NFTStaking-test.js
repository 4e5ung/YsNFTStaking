const { expect, assert } = require("chai");
const { ethers, waffle } = require("hardhat");
const { Bignumber } = require("ethers");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

describe("NFTStaking", function () {

    let accounts;
    let tokenContract;
    let nftStakingContract;
    let nftContract;
    const MaxUint256 = '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

    const overrides = {
        gasLimit: 9999999
    }

    beforeEach(async function () { 
        accounts = await ethers.getSigners();

        tokenContract = await (await ethers.getContractFactory("ERC20Token")).deploy();
        nftContract = await (await ethers.getContractFactory("PFPNFT")).deploy(accounts[0].address);
        nftStakingContract = await (await ethers.getContractFactory("NFTStaking")).deploy(
            accounts[0].address, 
            tokenContract.address,
            nftContract.address,
            Date.now(),
            Date.now()+100000000);


        await tokenContract.approve(accounts[0].address, MaxUint256);
        await tokenContract.transferFrom(accounts[0].address, nftStakingContract.address, ethers.utils.parseEther("100.0"));
        

        // 임의 민팅 및 권한 허용
        await nftContract.preNMint(accounts[0].address, 200);
        await nftContract.setApprovalForAll(nftStakingContract.address, true);

        // 레벨별 옵션 설정
        await nftStakingContract.setStakingOption(0, 1, 1);
        await nftStakingContract.setStakingOption(1, 10, 1);
        await nftStakingContract.setStakingOption(2, 100, 1);


        // 토큰별 레벨 설정
        let nftLevelInfo = [
            [0, 0],[0, 1],[0, 2],[0, 3],[0, 4],[0, 5],[0, 6],[0, 7],[0, 8],[0, 9],
            [1, 10],[1, 11],[1, 12],[1, 13],[1, 14],[1, 15],[1, 16],[1, 17],[1, 18],[1, 19],
            [1, 20],[1, 21],[1, 22],[1, 23],[1, 24],[1, 25],[1, 26],[1, 27],[1, 28],[1, 29]
        ]

        const abiCoder = ethers.utils.defaultAbiCoder;
        const encodeNftLevelInfo = abiCoder.encode(["tuple(uint8, uint256)[]"], [nftLevelInfo]);

        await nftStakingContract.setNftLevel(encodeNftLevelInfo);

        // 스테이킹
        await nftStakingContract.nftStaking([0,10,20]);
    });
    
    it("setStakingOption, 스테이킹 보상 설정", async function(){
        await nftStakingContract.setStakingOption(0, 1, 1);
    })

    it("setNftLevel, nft 레벨 설정", async function(){
        let nftLevelInfo = [
            [0, 0],[0, 1],[0, 2],[0, 3],[0, 4],[0, 5],[0, 6],[0, 7],[0, 8],[0, 9],
            [1, 10],[1, 11],[1, 12],[1, 13],[1, 14],[1, 15],[1, 16],[1, 17],[1, 18],[1, 19],
            [1, 20],[1, 21],[1, 22],[1, 23],[1, 24],[1, 25],[1, 26],[1, 27],[1, 28],[1, 29]
        ]

        const abiCoder = ethers.utils.defaultAbiCoder;
        const encodeNftLevelInfo = abiCoder.encode(["tuple(uint8, uint256)[]"], [nftLevelInfo]);

        tx = await nftStakingContract.setNftLevel(encodeNftLevelInfo);
        tx.wait();
    })

    it("nftStaking, nft스테이킹", async function(){        
        await nftStakingContract.nftStaking([1,11,21]);
    });

    it("nftUnStaking, nft언스테이킹", async function(){
        await helpers.mine(100);

        beforeBalance = await tokenContract.balanceOf(accounts[0].address);
        await nftStakingContract.nftUnStaking([10])
        afterBalance = await tokenContract.balanceOf(accounts[0].address);

        assert.equal( ethers.BigNumber.from(afterBalance).sub(beforeBalance), 1010 );

        expect(await nftContract.ownerOf(10))
        .to.equals(accounts[0].address)
    })


    it("tokensOfOwner, nft스테이킹 소유 토큰확인", async function(){        
        expect(await nftStakingContract.tokensOfOwner(accounts[0].address))
        .to.deep.eq([ethers.BigNumber.from(0), ethers.BigNumber.from(10), ethers.BigNumber.from(20)]);
    });

    it("stakeBalanceOf, nft스테이킹 소유 개수확인", async function(){        
        expect(await nftStakingContract.stakeBalanceOf(accounts[0].address))
        .to.equals(ethers.BigNumber.from(3));
    });

    it("calcReward, 보상 계산", async function(){
        await helpers.mine(100);
        expect(await nftStakingContract.calcReward(10))
        .to.equals(1000)
    })

    it("claimRewards, 보상 찾기", async function(){
        await helpers.mine(100);

        beforeBalance = await tokenContract.balanceOf(accounts[0].address);
        await nftStakingContract.claimRewards([10])
        afterBalance = await tokenContract.balanceOf(accounts[0].address);

        assert.equal( ethers.BigNumber.from(afterBalance).sub(beforeBalance), 1010 );
    })
    


});
