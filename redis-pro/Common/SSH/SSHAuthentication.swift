//
//  SSHAuthentication.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/8/5.
//

import Foundation
import NIO
import NIOSSH
import Logging

enum SSHClientError: Swift.Error {
    case passwordAuthenticationNotSupported
    case commandExecFailed
    case invalidChannelType
    case invalidData
}


final class ErrorHandler: ChannelInboundHandler {
    typealias InboundIn = Any

    let logger = Logger(label: "ssh-error-handler")
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("Error in pipeline: \(error)")
        context.close(promise: nil)
    }
}


/// A client user auth delegate that provides an interactive prompt for password-based user auth.
final class UserPasswordDelegate: NIOSSHClientUserAuthenticationDelegate {
    let logger = Logger(label: "ssh-password-delegate")
    
    private var username: String
    private var password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func nextAuthenticationType(availableMethods: NIOSSHAvailableUserAuthenticationMethods, nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>) {
        guard availableMethods.contains(.password) else {
            logger.error("Error: password auth not supported")
            nextChallengePromise.fail(SSHClientError.passwordAuthenticationNotSupported)
            return
        }
        
        nextChallengePromise.succeed(NIOSSHUserAuthenticationOffer(username: self.username, serviceName: "", offer: .password(.init(password: self.password))))
    }
}


final class AcceptAllHostKeysDelegate: NIOSSHClientServerAuthenticationDelegate {
    func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
        // Do not replicate this in your own code: validate host keys! This is a
        // choice made for expedience, not for any other reason.
        validationCompletePromise.succeed(())
    }
}
