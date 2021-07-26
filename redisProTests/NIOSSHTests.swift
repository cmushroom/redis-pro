//
//  NIOSSHTests.swift
//  redisProTests
//
//  Created by chengpanwang on 2021/7/26.
//

import XCTest
import NIO
import NIOSSH
import Crypto

class NIOSSHTests: XCTestCase {
    static let _version = "SSH-2.0-SwiftNIOSSH_1.0"
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func channelInit(c:Channel, type:SSHChannelType) -> EventLoopFuture<Void> {
        return c.closeFuture
    }
    
    func testHandlerInitializationOnAdd() throws {
        let allocator = ByteBufferAllocator()
        let channel = EmbeddedChannel()
        let handler = NIOSSHHandler(role: .client(.init(userAuthDelegate: InfinitePasswordDelegate(), serverAuthDelegate: AcceptAllHostKeysDelegate())), allocator: allocator, inboundChildChannelInitializer: nil)

        _ = try channel.connect(to: .init(unixDomainSocketPath: "/foo"))

        XCTAssertNoThrow(try channel.pipeline.addHandler(handler).wait())
        XCTAssertEqual(try channel.readOutbound(as: IOData.self), .byteBuffer(allocator.buffer(string: NIOSSHTests._version + "\r\n")))
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let clientDelegate = NIOSSHClientAuthenticationDelegate()
        let clientConfig = SSHClientConfiguration(userAuthDelegate: clientDelegate, serverAuthDelegate: clientDelegate)
        let handler:NIOSSHHandler = NIOSSHHandler(role: .client(clientConfig), allocator: ByteBufferAllocator()
                                                  , inboundChildChannelInitializer: channelInit)
        
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
        let client = ClientBootstrap(group: eventLoop)
            .channelInitializer({ channel in
                channel.pipeline.addHandler(handler)
            })
        print("........... \(client)")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

class NIOSSHClientAuthenticationDelegate: NIOSSHClientUserAuthenticationDelegate,NIOSSHClientServerAuthenticationDelegate {
    func nextAuthenticationType(availableMethods: NIOSSHAvailableUserAuthenticationMethods, nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>) {
        print("nextAuthenticationType...")
    }
    
    func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
        print("validateHostKey...")
    }
    
    
}



private enum Fixtures {
    // P256 ECDSA key, generated using `ssh-keygen -m PEM -t ecdsa`
    static let privateKey = """
    -----BEGIN EC PRIVATE KEY-----
    MHcCAQEEIJFqt5pH9xGvuoaI5kzisthTa0EXVgy+fC4bAtdwBR07oAoGCCqGSM49
    AwEHoUQDQgAEyJP6dnY46GvyP65L9FgFxNdN+rNWy4PqIwCrwJWY6ss/sTSbMkdA
    4D7gh+fWyft3EdRtcAsw3raU/G2S+N1iAA==
    -----END EC PRIVATE KEY-----
    """

    // Raw private key data, since `PrivateKey(pemRepresentation:)` is not available on every supported platform
    static let privateKeyRaw = Data([145, 106, 183, 154, 71, 247, 17, 175, 186, 134, 136, 230, 76, 226, 178, 216, 83, 107, 65, 23, 86, 12, 190, 124, 46, 27, 2, 215, 112, 5, 29, 59])

    // A P256 user key. id "User P256 key" serial 0 for foo,bar valid from 2020-06-03T17:50:15 to 2070-04-02T17:51:15
    // Generated using ssh-keygen -s ca-key -I "User P256 key" -n "foo,bar" -V "-1m:+2600w" user-p256
    static let certificateKey = """
    ecdsa-sha2-nistp256-cert-v01@openssh.com AAAAKGVjZHNhLXNoYTItbmlzdHAyNTYtY2VydC12MDFAb3BlbnNzaC5jb20AAAAgHmvoERZ+BRKhlCAKoPlVQLcHO5oNxyGeXHnmI0DLL/8AAAAIbmlzdHAyNTYAAABBBMiT+nZ2OOhr8j+uS/RYBcTXTfqzVsuD6iMAq8CVmOrLP7E0mzJHQOA+4Ifn1sn7dxHUbXALMN62lPxtkvjdYgAAAAAAAAAAAAAAAAEAAAANVXNlciBQMjU2IGtleQAAAA4AAAADZm9vAAAAA2JhcgAAAABgABLaAAAAAL26NxYAAAAAAAAAggAAABVwZXJtaXQtWDExLWZvcndhcmRpbmcAAAAAAAAAF3Blcm1pdC1hZ2VudC1mb3J3YXJkaW5nAAAAAAAAABZwZXJtaXQtcG9ydC1mb3J3YXJkaW5nAAAAAAAAAApwZXJtaXQtcHR5AAAAAAAAAA5wZXJtaXQtdXNlci1yYwAAAAAAAAAAAAAAiAAAABNlY2RzYS1zaGEyLW5pc3RwMzg0AAAACG5pc3RwMzg0AAAAYQR2JTEl2nF7dd6AS6TFxD9DkjMOaJHeXOxt4aIptTEf0x1DsjktgFUChKi2bPrXd2OsmAq6uUxlgzRmNnXyhV/fZy6iQqtpMUf/wj91IXq5GZ5+ruHluG4iy+8Tg6jTs5EAAACDAAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAABoAAAAMHIoH34qNeg6LDTiSUF13KvPImQljh1Se5cxtrZZ3bCBAK2DUZQsAitxc8Ju4jY2zQAAADBkQfjSYa5wr2y61D54kWSIDiqOjgEAnfjJkyglQcYU4P1ULCFXJ15tIg3GRBY4U/s= artemredkin@Artems-MacBook-Pro.local
    """
}

/// An authentication delegate that yields passwords forever.
final class InfinitePasswordDelegate: NIOSSHClientUserAuthenticationDelegate {
    func nextAuthenticationType(availableMethods: NIOSSHAvailableUserAuthenticationMethods, nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>) {
        let request = NIOSSHUserAuthenticationOffer(username: "foo", serviceName: "", offer: .password(.init(password: "bar")))
        nextChallengePromise.succeed(request)
    }
}

final class InfinitePrivateKeyDelegate: NIOSSHClientUserAuthenticationDelegate {
    let key = NIOSSHPrivateKey(p256Key: .init())

    func nextAuthenticationType(availableMethods: NIOSSHAvailableUserAuthenticationMethods, nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>) {
        let request = NIOSSHUserAuthenticationOffer(username: "foo", serviceName: "", offer: .privateKey(.init(privateKey: self.key)))
        nextChallengePromise.succeed(request)
    }
}

final class InfiniteCertificateDelegate: NIOSSHClientUserAuthenticationDelegate {
    let privateKey: NIOSSHPrivateKey
    let certifiedKey: NIOSSHCertifiedPublicKey

    init() throws {
        self.privateKey = try NIOSSHPrivateKey(p256Key: P256.Signing.PrivateKey(rawRepresentation: Fixtures.privateKeyRaw))
        self.certifiedKey = try NIOSSHCertifiedPublicKey(NIOSSHPublicKey(openSSHPublicKey: Fixtures.certificateKey))!
    }

    func nextAuthenticationType(availableMethods: NIOSSHAvailableUserAuthenticationMethods, nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>) {
        let request = NIOSSHUserAuthenticationOffer(username: "foo", serviceName: "", offer: .privateKey(.init(privateKey: self.privateKey, certifiedKey: self.certifiedKey)))
        nextChallengePromise.succeed(request)
    }
}

final class AcceptAllHostKeysDelegate: NIOSSHClientServerAuthenticationDelegate {
    func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
        validationCompletePromise.succeed(())
    }
}
