import Foundation

func handleSharedFile(_ fileURL: URL, machO: inout [MachOPatcher]) {
    let patcher = MachOPatcher(fileURL)
    machO.append(patcher)
    install_exit_hook()
    if let url = patcher.patchExecutable() {
        Execute.run(dylibPath: url.path)
    }
}
