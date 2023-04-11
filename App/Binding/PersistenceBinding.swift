//
//  This file is part of Blokada.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Copyright © 2023 Blocka AB. All rights reserved.
//
//  @author Kar
//

import Foundation
import Factory

class PersistenceBinding: PersistenceOps {
    
    @Injected(\.flutter) private var flutter

    private let localStorage = UserDefaults.standard
    private let iCloud = NSUbiquitousKeyValueStore()
    private let keychain = KeychainSwift()

    init() {
        keychain.synchronizable = true
        PersistenceOpsSetup.setUp(
            binaryMessenger: flutter.getMessenger() , api: self
        )
    }

    func doSave(key: String, value: String, isSecure: Bool, isBackup: Bool,
                completion: @escaping (Result<Void, Error>) -> Void) {
        if (isSecure) {
            self.keychain.set(value, forKey: key)
            completion(.success(()))
        } else if (isBackup) {
            self.iCloud.set(value, forKey: key)
            self.iCloud.synchronize()
            completion(.success(()))
        } else {
            self.localStorage.set(value, forKey: key)
            completion(.success(()))
        }
    }
    
    func doLoad(key: String, isSecure: Bool, isBackup: Bool,
                completion: @escaping (Result<String, Error>) -> Void) {
        if (isSecure) {
            guard let it = self.keychain.get(key) else {
                return completion(.failure(CommonError.emptyResult))
            }
            completion(.success(it))
        } else if (isBackup) {
            guard let it = self.iCloud.string(forKey: key) else {
                return completion(.failure(CommonError.emptyResult))
            }
            completion(.success(it))
        } else {
            guard let it = self.localStorage.string(forKey: key) else {
                return completion(.failure(CommonError.emptyResult))
            }
            completion(.success(it))
        }
    }

    func doDelete(key: String, isSecure: Bool, isBackup: Bool,
                  completion: @escaping (Result<Void, Error>) -> Void) {
        if (isSecure) {
            self.keychain.delete(key)
            completion(.success(()))
        } else if (isBackup) {
            self.iCloud.removeObject(forKey: key)
            completion(.success(()))
        } else {
            self.localStorage.removeObject(forKey: key)
            completion(.success(()))
        }
    }
}

extension Container {
    var persistence: Factory<PersistenceBinding> {
        self { PersistenceBinding() }.singleton
    }
}
