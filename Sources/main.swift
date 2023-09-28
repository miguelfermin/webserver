// The Swift Programming Language
// https://docs.swift.org/swift-book

import Hummingbird
import HummingbirdFoundation

let app = HBApplication(configuration: .init(address: .hostname("127.0.0.1", port: 8080)))
app.decoder = JSONDecoder()
app.encoder = JSONEncoder()
app.router.get("users", use: actionHandlerVoid(getUsers))
app.router.get("users/:id", use: actionHandlerVoid(getUserByID))
app.router.post("users", use: actionHandler(createUser))
app.router.put("users", use: actionHandler(updateUser))

struct UserCreateRequest: HBResponseCodable { let name: String }
struct UserUpdateRequest: HBResponseCodable { let id: Int; let name: String }
class User: Codable { let id: Int; var name: String; init(id: Int, name: String) { self.id = id; self.name = name } }
extension User: HBResponseCodable {}

private var users = [User]()

func createUser(request: Request<UserCreateRequest>) async throws -> User {
    let user = User(id: users.count + 1, name: request.model.name)
    users.append(user)
    return user
}

func updateUser(request: Request<UserUpdateRequest>) async throws -> User {
    guard let user = users.first(where: { request.model.id == $0.id }) else {
        throw ServerError(.notFound, code: 10, message: "User not found")
    }
    user.name = request.model.name
    return user
}

func getUsers(input: RequestVoid) async throws -> [User] {
    users
}

func getUserByID(input: RequestVoid) async throws -> User {
    guard let ids = input.params["id"], let id = Int(ids) else {
        throw ServerError(.notFound, code: 10, message: "User not found")
    }
    guard let user = users.first(where: { id == $0.id }) else {
        throw ServerError(.notFound, code: 10, message: "User not found")
    }
    return user
}

try app.start()

// Test getting ENV variables
if let env = try? HBEnvironment.dotEnv() {
    print("\n")
    print("PRODUCT_BUILD::                  \(env.get("PRODUCT_BUILD") ?? "NA")")
    print("PRODUCT_SERVER_PORT::            \(env.get("PRODUCT_SERVER_PORT") ?? "NA")")
    print("PRODUCT_SECRET_KEY_APP::         \(env.get("PRODUCT_SECRET_KEY_APP") ?? "NA")")
    print("PRODUCT_SECRET_KEY_SERVER::      \(env.get("PRODUCT_SECRET_KEY_SERVER") ?? "NA")")
    print("PRODUCT_SECRET_KEY_SIGNER::      \(env.get("PRODUCT_SECRET_KEY_SIGNER") ?? "NA")")
    print("PRODUCT_POSTGRES_USER::          \(env.get("PRODUCT_POSTGRES_USER") ?? "NA")")
    print("PRODUCT_POSTGRES_PASSWORD::      \(env.get("PRODUCT_POSTGRES_PASSWORD") ?? "NA")")
    print("PRODUCT_POSTGRES_HOST::          \(env.get("PRODUCT_POSTGRES_HOST") ?? "NA")")
    print("PRODUCT_POSTGRES_PORT::          \(env.get("PRODUCT_POSTGRES_PORT") ?? "NA")")
    print("PRODUCT_POSTGRES_DATABASE::      \(env.get("PRODUCT_POSTGRES_DATABASE") ?? "NA")")
    print("PRODUCT_GO_TESTS::               \(env.get("PRODUCT_GO_TESTS") ?? "NA")")
    print("\n")
}

app.wait()
