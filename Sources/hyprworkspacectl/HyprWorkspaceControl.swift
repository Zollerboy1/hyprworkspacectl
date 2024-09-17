import ArgumentParser
import Foundation
import SwiftCommand

let hyprctl = Command.findInPath(withName: "hyprctl")!.addArgument("-j")


struct Workspace: Decodable {
    let id: Int
    let name: String
    let monitorID: Int
    let windows: Int
}


@main
struct HyprWorkspaceControl: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "hyprworkspacectl",
        abstract: "Control the workspaces of the Hypr desktop environment",
        subcommands: [List.self, Move.self],
        defaultSubcommand: List.self
    )
}

struct List: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "List the available workspaces"
    )

    func run() async throws {
        guard try await hyprctl.addArgument("workspaces").status.terminatedSuccessfully else {
            throw ExitCode.failure
        }
    }
}

struct Move: AsyncParsableCommand {
    enum WorkspaceArgument: ExpressibleByArgument {
        case id(Int)
        case name(String)
        case left, right

        init?(argument: String) {
            if let id = Int(argument) {
                self = .id(id)
            } else if argument == "left" {
                self = .left
            } else if argument == "right" {
                self = .right
            } else {
                self = .name(argument)
            }
        }
    }

    static var configuration = CommandConfiguration(
        abstract: "Move to the specified workspace"
    )

    @Argument(help: "The workspace to move to (can be 'left' or 'right', or a workspace ID or name)")
    var workspace: WorkspaceArgument

    func run() async throws {
        let workspaceString: String
        switch workspace {
        case let .id(id): workspaceString = "\(id)"
        case let .name(name): workspaceString = "name:\(name)"
        default:
            let decoder = JSONDecoder()

            let workspacesData = try await hyprctl.addArgument("workspaces").outputData
            let workspaces = try decoder.decode([Workspace].self, from: workspacesData)
                .sorted { $0.id < $1.id }

            let activeWorkspaceData = try await hyprctl.addArgument("activeworkspace").outputData
            let activeWorkspace = try decoder.decode(Workspace.self, from: activeWorkspaceData)

            let workspacesOnMonitor = workspaces
                .filter { $0.monitorID == activeWorkspace.monitorID }

            if case .left = workspace {
                guard let leftWorkspace = workspacesOnMonitor.last(where: { $0.id < activeWorkspace.id }) else {
                    return
                }

                workspaceString = "\(leftWorkspace.id)"
            } else if let rightWorkspaceID = workspacesOnMonitor.first(where: { $0.id > activeWorkspace.id })?.id {
                workspaceString = "\(rightWorkspaceID)"
            } else if activeWorkspace.windows > 0 {
                workspaceString = "\(workspaces.last!.id + 1)"
            } else {
                return
            }
        }

        guard try await hyprctl.addArguments("dispatch", "workspace", workspaceString).status.terminatedSuccessfully else {
            throw ExitCode.failure
        }
    }
}
