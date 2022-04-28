import { expect } from "chai";
import { ethers } from "hardhat";
import {
    abiCoder,
    deployerAddress,
    FIRST_LINKLIST_ID,
    FIRST_PROFILE_ID,
    makeSuiteCleanRoom,
    MOCK_PROFILE_HANDLE,
    MOCK_PROFILE_HANDLE2,
    MOCK_PROFILE_URI,
    FIRST_NOTE_ID,
    SECOND_PROFILE_ID,
    MOCK_NOTE_URI,
    bytes32Zero,
    LinkItemTypeProfile,
    LinkItemTypeAddress,
    LinkItemTypeNote,
    LinkItemTypeERC721,
    LinkItemTypeList,
    LinkItemTypeAny,
    user,
    userAddress,
    userTwo,
    userTwoAddress,
    web3Entry,
    userThree,
    linklist,
    deployer,
    userThreeAddress,
    FollowLinkType,
    LikeLinkType,
    SECOND_LINKLIST_ID,
    feeMintModule,
    approvalMintModule,
} from "./setup.test";
import { makePostNoteData, makeProfileData, matchEvent, matchNote } from "./helpers/utils";
import { ERRORS } from "./helpers/errors";
import { formatBytes32String } from "@ethersproject/strings/src.ts/bytes32";
// eslint-disable-next-line node/no-missing-import,camelcase
import { ApprovalMintModule__factory, MintNFT__factory } from "../typechain";
import { BigNumber } from "ethers";

makeSuiteCleanRoom("Note and mint functionality ", function () {
    context("Generic", function () {
        beforeEach(async function () {
            await web3Entry.createProfile(makeProfileData(MOCK_PROFILE_HANDLE));
            await web3Entry.createProfile(makeProfileData(MOCK_PROFILE_HANDLE2));
        });

        context("Negatives", function () {
            it("UserTwo should fail to post note at a profile owned by user 1", async function () {
                await expect(
                    web3Entry
                        .connect(userTwo)
                        .postNote(makePostNoteData(FIRST_PROFILE_ID.toString()))
                ).to.be.revertedWith(ERRORS.NOT_PROFILE_OWNER);
            });

            it("UserTwo should fail to post note for profile link at a profile owned by user 1", async function () {
                // link profile
                await web3Entry.linkProfile(FIRST_PROFILE_ID, SECOND_PROFILE_ID, FollowLinkType);

                // post note for profile link
                await expect(
                    web3Entry
                        .connect(userTwo)
                        .postNote4ProfileLink(
                            makePostNoteData(FIRST_PROFILE_ID.toString()),
                            FIRST_PROFILE_ID,
                            SECOND_PROFILE_ID,
                            FollowLinkType
                        )
                ).to.be.revertedWith(ERRORS.NOT_PROFILE_OWNER);
            });
        });

        context("Scenarios", function () {
            it("User should post note", async function () {
                // post note
                const noteData = makePostNoteData(FIRST_PROFILE_ID.toString());
                await expect(web3Entry.postNote(noteData)).to.not.be.reverted;

                let note = await web3Entry.getNote(noteData.profileId, FIRST_NOTE_ID);
                matchNote(note, [
                    bytes32Zero,
                    0,
                    bytes32Zero,
                    noteData.contentUri,
                    ethers.constants.AddressZero,
                    ethers.constants.AddressZero,
                    ethers.constants.AddressZero,
                ]);

                // mint note
                await web3Entry
                    .connect(userThree)
                    .mintNote(FIRST_PROFILE_ID, FIRST_NOTE_ID, userTwoAddress, []);
                await web3Entry
                    .connect(userThree)
                    .mintNote(FIRST_PROFILE_ID, FIRST_NOTE_ID, userThreeAddress, []);

                note = await web3Entry.getNote(FIRST_PROFILE_ID, FIRST_NOTE_ID);
                expect(note.mintNFT).to.not.equal(ethers.constants.AddressZero);
                const mintNFT = MintNFT__factory.connect(note.mintNFT, deployer);
                expect(await mintNFT.ownerOf(1)).to.equal(userTwoAddress);
                expect(await mintNFT.ownerOf(2)).to.equal(userThreeAddress);
            });

            it("User should post note with profile link", async function () {
                // link profile
                await web3Entry.linkProfile(FIRST_PROFILE_ID, SECOND_PROFILE_ID, FollowLinkType);

                // post note
                const noteData = makePostNoteData("1");
                await expect(
                    web3Entry.postNote4ProfileLink(
                        noteData,
                        FIRST_PROFILE_ID,
                        SECOND_PROFILE_ID,
                        FollowLinkType
                    )
                ).to.not.be.reverted;

                let note = await web3Entry.getNote(noteData.profileId, FIRST_NOTE_ID);
                matchNote(note, [
                    LinkItemTypeProfile,
                    FIRST_LINKLIST_ID,
                    ethers.utils.hexZeroPad(ethers.utils.hexlify(SECOND_PROFILE_ID), 32),
                    noteData.contentUri,
                    ethers.constants.AddressZero,
                    ethers.constants.AddressZero,
                    ethers.constants.AddressZero,
                ]);

                // mint note
                await web3Entry
                    .connect(userThree)
                    .mintNote(FIRST_PROFILE_ID, FIRST_NOTE_ID, userTwoAddress, []);

                note = await web3Entry.getNote(FIRST_PROFILE_ID, FIRST_NOTE_ID);
                expect(await MintNFT__factory.connect(note.mintNFT, deployer).ownerOf(1)).to.equal(
                    userTwoAddress
                );
            });

            it("User should post note with address link", async function () {
                // link address
                await web3Entry.linkAddress(FIRST_PROFILE_ID, userThreeAddress, FollowLinkType);

                // post note
                const noteData = makePostNoteData();
                await expect(
                    web3Entry.postNote4ProfileLink(
                        noteData,
                        FIRST_PROFILE_ID,
                        userThreeAddress,
                        FollowLinkType
                    )
                ).to.not.be.reverted;

                let note = await web3Entry.getNote(noteData.profileId, FIRST_NOTE_ID);
                matchNote(note, [
                    LinkItemTypeProfile,
                    FIRST_LINKLIST_ID,
                    ethers.utils.hexZeroPad(ethers.utils.hexlify(userThreeAddress), 32),
                    noteData.contentUri,
                    ethers.constants.AddressZero,
                    ethers.constants.AddressZero,
                    ethers.constants.AddressZero,
                ]);

                // mint note
                await web3Entry
                    .connect(userThree)
                    .mintNote(FIRST_PROFILE_ID, FIRST_NOTE_ID, userTwoAddress, []);

                note = await web3Entry.getNote(FIRST_PROFILE_ID, FIRST_NOTE_ID);
                expect(await MintNFT__factory.connect(note.mintNFT, deployer).ownerOf(1)).to.equal(
                    userTwoAddress
                );
            });

            it("User should post note with linklist link", async function () {
                // link profile
                await web3Entry.linkProfile(SECOND_PROFILE_ID, FIRST_PROFILE_ID, FollowLinkType);

                // link linklist
                await web3Entry.linkLinklist(FIRST_PROFILE_ID, FIRST_LINKLIST_ID, LikeLinkType);

                // post note
                const noteData = makePostNoteData();
                await expect(
                    web3Entry.postNote4LinklistLink(
                        noteData,
                        FIRST_PROFILE_ID,
                        SECOND_LINKLIST_ID,
                        LikeLinkType
                    )
                ).to.not.be.reverted;

                let note = await web3Entry.getNote(noteData.profileId, FIRST_NOTE_ID);
                matchNote(note, [
                    LinkItemTypeList,
                    SECOND_LINKLIST_ID,
                    ethers.utils.hexZeroPad(ethers.utils.hexlify(SECOND_LINKLIST_ID), 32),
                    noteData.contentUri,
                    ethers.constants.AddressZero,
                    ethers.constants.AddressZero,
                    ethers.constants.AddressZero,
                ]);

                // mint note
                await web3Entry
                    .connect(userThree)
                    .mintNote(FIRST_PROFILE_ID, FIRST_NOTE_ID, userTwoAddress, []);

                note = await web3Entry.getNote(FIRST_PROFILE_ID, FIRST_NOTE_ID);
                expect(await MintNFT__factory.connect(note.mintNFT, deployer).ownerOf(1)).to.equal(
                    userTwoAddress
                );
            });
        });

        context("Mint Module", function () {
            it("User should post note with mintModule, and userTwo should mint note", async function () {
                // post note
                const noteData = makePostNoteData(FIRST_PROFILE_ID.toString());

                await expect(
                    web3Entry.postNote({
                        profileId: FIRST_PROFILE_ID,
                        contentUri: MOCK_NOTE_URI,
                        linkModule: ethers.constants.AddressZero,
                        linkModuleInitData: [],
                        mintModule: approvalMintModule.address,
                        mintModuleInitData: abiCoder.encode(["address[]"], [[userTwoAddress]]),
                    })
                ).to.not.be.reverted;

                let note = await web3Entry.getNote(noteData.profileId, FIRST_NOTE_ID);
                matchNote(note, [
                    bytes32Zero,
                    0,
                    bytes32Zero,
                    noteData.contentUri,
                    ethers.constants.AddressZero,
                    approvalMintModule.address,
                    ethers.constants.AddressZero,
                ]);

                const ApproveMint = ApprovalMintModule__factory.connect(
                    approvalMintModule.address,
                    deployer
                );

                // const isApproved = await ApproveMint.isApproved(
                //     userAddress,
                //     FIRST_PROFILE_ID,
                //     FIRST_NOTE_ID,
                //     userTwoAddress
                // );
                // console.log(isApproved);

                // mint note
                await web3Entry
                    .connect(userThree)
                    .mintNote(FIRST_PROFILE_ID, FIRST_NOTE_ID, userTwoAddress, []);
                await expect(
                    web3Entry
                        .connect(userThree)
                        .mintNote(FIRST_PROFILE_ID, FIRST_NOTE_ID, userThreeAddress, [])
                ).to.be.revertedWith(ERRORS.NOT_APROVED);

                note = await web3Entry.getNote(FIRST_PROFILE_ID, FIRST_NOTE_ID);
                expect(note.mintNFT).to.not.equal(ethers.constants.AddressZero);
                const mintNFT = MintNFT__factory.connect(note.mintNFT, deployer);
                expect(await mintNFT.ownerOf(1)).to.equal(userTwoAddress);
            });
        });
    });
});
