
import SwiftUI

struct SidebarView: View {
    @ObservedObject var profileViewModel: ControllerProfileViewModel
    @State private var showingAddController = false
    @State private var showingAddProfile = false
    @State private var newControllerName = ""
    @State private var newProfileName = ""
    @State private var isRenameController = false
    @State private var isRenameProfile = false
    @State private var fixControllerName = ""
    @State private var fixProfileName = ""

    var body: some View {
        List(selection: $profileViewModel.selectedProfileId) {
            ForEach($profileViewModel.controllers) { $controller in
                DisclosureGroup(isExpanded: $controller.isExpanded) {
                    ForEach(controller.profiles) { profile in
                        ProfileRow(
                            profile: profile,
//                            controller: controller, //いる？
                            isSelected: profileViewModel.selectedProfileId == profile.id
                        )
                        .tag(profile.id) //コントローラー階層の個々プロフィールのID
                        .contextMenu {
                            Button(role: .destructive) {
                                profileViewModel.removeProfile(controllerId: controller.id, profileId: profile.id)
                            } label: {
                                Label("プロファイルを削除", systemImage: "trash")
                            }

                            Button {
                                isRenameProfile = true
                            } label: {
                                Label("名称を変更", systemImage: "pencil.and.list.clipboard")
                            }
                        }
                    }
                } label: {
                    ControllerHeader(
                        controller: controller
//                        profileViewModel: profileViewModel
                    )
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button(role: .destructive) {
                            profileViewModel.removeController(id: controller.id)
                        } label: {
                            Label("コントローラーを削除", systemImage: "trash")
                        }

                        Button {
                            isRenameController = true
                        } label: {
                            Label("名称を変更", systemImage: "pencil.and.list.clipboard")
                        }

                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("コントローラー")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button {
                        showingAddController = true
                    } label: {
                        Label("コントローラーを追加", systemImage: "plus.circle")
                    }

                    if profileViewModel.selectedController != nil {
                        Button {
                            showingAddProfile = true
                        } label: {
                            Label("プロファイルを追加", systemImage: "folder.badge.plus")
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddController) {
            AddControllerSheet(
                controllerName: $newControllerName,
                isPresented: $showingAddController,
                onAdd: {
                    let controller = profileViewModel.addController(name: newControllerName)
                    profileViewModel.selectedControllerId = controller.id
                    if let firstProfile = controller.profiles.first {
                        profileViewModel.selectedProfileId = firstProfile.id
                    }
                    newControllerName = ""
                }
            )
        }
        .sheet(isPresented: $showingAddProfile) {
            AddProfileSheet(
                profileName: $newProfileName,
                isPresented: $showingAddProfile,
                onAdd: {
                    if let controllerId = profileViewModel.selectedControllerId {
                        let profile = profileViewModel.addProfile(to: controllerId, name: newProfileName)
                        if let profile = profile {
                            profileViewModel.selectedProfileId = profile.id
                        }
                        newProfileName = ""
                    }
                }
            )
        }
        .sheet(isPresented: $isRenameController){
            RenameControllerSheet(controllerName: $fixControllerName, isPresented: $isRenameController) {
                guard let selectedControllerId = profileViewModel.selectedControllerId else { return }
                if let index = profileViewModel.controllers.firstIndex { $0.id == selectedControllerId } {
                    profileViewModel.controllers[index].name = fixControllerName
                }
            }
        }
        .sheet(isPresented: $isRenameProfile){
            RenameProfileSheet(profileName: $fixProfileName, isPresented: $isRenameProfile) {
                guard let selectedControllerId = profileViewModel.selectedControllerId, let selectedProfileId = profileViewModel.selectedProfileId else { return }
                guard let controllerIndex = profileViewModel.controllers.firstIndex(where: { $0.id == selectedControllerId }) else { return }
                guard let profileIndex = profileViewModel.controllers[controllerIndex].profiles.firstIndex(where: { $0.id == selectedProfileId }) else { return }

                profileViewModel.controllers[controllerIndex].profiles[profileIndex].name = fixProfileName

            }
        }
    }
}

struct ControllerHeader: View {
    let controller: Controller
//    @ObservedObject var profileViewModel: ControllerProfileViewModel

    var body: some View {
        HStack {
            Image(systemName: controller.isConnected ? "gamecontroller.fill" : "gamecontroller")
                .foregroundColor(controller.isConnected ? .green : .secondary)
            Text(controller.name)
                .font(.headline)
            Spacer()
        }
    }
}

struct ProfileRow: View {
    let profile: Profile
//    let controller: Controller
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: profile.icon)
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .frame(width: 20)
            Text(profile.name)
                .foregroundColor(isSelected ? .primary : .secondary)
            Spacer()
        }
        .padding(.vertical, 2)
    }
}



struct AddControllerSheet: View {
    @Binding var controllerName: String
    @Binding var isPresented: Bool
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("コントローラーを追加")
                .font(.title2)
                .fontWeight(.semibold)

            TextField("コントローラー名", text: $controllerName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    onAdd()
                    isPresented = false
                }

            HStack(spacing: 12) {
                Button("キャンセル") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Button("追加") {
                    onAdd()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(controllerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

struct AddProfileSheet: View {
    @Binding var profileName: String
    @Binding var isPresented: Bool
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("プロファイルを追加")
                .font(.title2)
                .fontWeight(.semibold)

            TextField("プロファイル名", text: $profileName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    onAdd()
                    isPresented = false
                }

            HStack(spacing: 12) {
                Button("キャンセル") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Button("追加") {
                    onAdd()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(profileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

struct RenameControllerSheet: View {
    @Binding var controllerName: String
    @Binding var isPresented: Bool
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("名称を変更")
                .font(.title2)
                .fontWeight(.semibold)

            TextField("コントローラー名", text: $controllerName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    onAdd()
                    isPresented = false
                }

            HStack(spacing: 12) {
                Button("キャンセル") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Button("変更") {
                    onAdd()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(controllerName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

struct RenameProfileSheet: View {
    @Binding var profileName: String
    @Binding var isPresented: Bool
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("名称を変更")
                .font(.title2)
                .fontWeight(.semibold)

            TextField("プロフィール名", text: $profileName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    onAdd()
                    isPresented = false
                }

            HStack(spacing: 12) {
                Button("キャンセル") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Button("変更") {
                    onAdd()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(profileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
