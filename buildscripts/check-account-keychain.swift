// Runs in a temporary app bundle with NNWCustomBuild=true. Uses fake data only.
import Foundation
import Security
import Secrets

let server = "nnw-regression-" + UUID().uuidString + ".invalid"
let user = "temporary-test-user"
let legacy: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
	kSecAttrServer as String: server, kSecAttrAccount as String: user,
	kSecAttrSecurityDomain as String: CredentialsType.readerBasic.rawValue]
var legacyItem = legacy
legacyItem[kSecValueData as String] = Data("legacy-value-must-survive".utf8)
precondition(SecItemAdd(legacyItem as CFDictionary, nil) == errSecSuccess)
defer { SecItemDelete(legacy as CFDictionary) }

do {
	precondition(Bundle.main.object(forInfoDictionaryKey: "NNWCustomBuild") as? Bool == true)
	for type in [CredentialsType.readerBasic, .readerAPIKey] {
		let original = Credentials(type: type, username: user, secret: "temporary-value")
		try CredentialsManager.storeCredentials(original, server: server)
		defer { try? CredentialsManager.removeCredentials(type: type, server: server, username: user) }
		let read = try CredentialsManager.retrieveCredentials(type: type, server: server, username: user)
		precondition(read == original)
		let updated = Credentials(type: type, username: user, secret: "updated-value")
		try CredentialsManager.storeCredentials(updated, server: server)
		let reread = try CredentialsManager.retrieveCredentials(type: type, server: server, username: user)
		precondition(reread == updated)
		let otherServer = try CredentialsManager.retrieveCredentials(type: type, server: server + ".other", username: user)
		precondition(otherServer == nil)
		var oldQuery = legacy
		oldQuery[kSecReturnData as String] = true
		var oldValue: CFTypeRef?
		precondition(SecItemCopyMatching(oldQuery as CFDictionary, &oldValue) == errSecSuccess)
		precondition(oldValue as? Data == Data("legacy-value-must-survive".utf8))
		try CredentialsManager.removeCredentials(type: type, server: server, username: user)
		let removed = try CredentialsManager.retrieveCredentials(type: type, server: server, username: user)
		precondition(removed == nil)
	}
	print("PASS: Reader password/token create, read, update, remove, server isolation and legacy preservation")
} catch {
	print(error.localizedDescription)
	exit(1)
}
