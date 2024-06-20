import SwiftUI
import HomeKit

struct ScrollView: View {
    @ObservedObject var homeKitManager = HomeKitManager() // ObservedObject로 선언
    @Binding var selectedHome: HMHome?
    @Binding var selectedRoom: HMRoom?
    @Binding var selectedAccessory: HMAccessory?
    
    private let lightController = LightController()
    @StateObject private var motionManager = MotionManager()
    @Binding var isShakeToToggleEnabled: Bool // 부모 뷰와 상태를 공유하기 위한 바인딩
    
    @Environment(\.presentationMode) var presentationMode // presentationMode 환경 변수 추가

    var body: some View {
        NavigationStack {
                VStack {
                    // 사용자가 홈, 방, 액세서리를 선택할 수 있는 리스트
                    List {
                        // 홈 선택 섹션
                        Section(header: Text("Select Home")) {
                            Picker("Home", selection: $homeKitManager.selectedHome) {
                                ForEach(homeKitManager.homes, id: \.self) { home in
                                    Text(home.name).tag(home as HMHome?)
                                }
                            }
                        }
                        
                        // 사용자가 홈을 선택한 경우 방 선택 섹션을 표시
                        if let selectedHome = homeKitManager.selectedHome {
                            Section(header: Text("Select Room")) {
                                Picker("Room", selection: $homeKitManager.selectedRoom) {
                                    ForEach(selectedHome.rooms, id: \.self) { room in
                                        Text(room.name).tag(room as HMRoom?)
                                    }
                                }
                            }
                        }
                        
                        // 사용자가 방을 선택한 경우 액세서리 선택 섹션을 표시
                        if let selectedRoom = homeKitManager.selectedRoom {
                            Section(header: Text("Select Accessory")) {
                                Picker("Accessory", selection: $homeKitManager.selectedAccessory) {
                                    ForEach(selectedRoom.accessories, id: \.self) { accessory in
                                        Text(accessory.name).tag(accessory as HMAccessory?)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Done 버튼을 추가하여 설정을 완료하고 SettingView로 돌아가도록 함
                    Button(action: {
                        self.isShakeToToggleEnabled = true // 상태를 부모 뷰로 전달
                        presentationMode.wrappedValue.dismiss() // 현재 뷰를 닫음
                    }) {
                        Text("Done")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                    
                }
                .navigationBarTitle("Potter")
                .onChange(of: motionManager.isShaken) { _, newValue in
                    handleShake(newValue)
                }
                .onChange(of: homeKitManager.selectedHome) {_, newValue in
                    self.selectedHome = newValue
                }
                .onChange(of: homeKitManager.selectedRoom) {_, newValue in
                    self.selectedRoom = newValue
                }
                .onChange(of: homeKitManager.selectedAccessory) {_, newValue in
                    self.selectedAccessory = newValue
                }
        }
    }
    
    // 흔들림 제어 함수
    private func handleShake(_ isShaken: Bool) {
        if isShakeToToggleEnabled && isShaken {
            if let selectedAccessory = homeKitManager.selectedAccessory {
                lightController.toggleLight(on: homeKitManager.brightness == 0, for: selectedAccessory)
                homeKitManager.brightness = homeKitManager.brightness == 0 ? 100 : 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            motionManager.isShaken = false
        }
    }
}
struct ScrollView_Previews: PreviewProvider {
    static var previews: some View {
        let homeKitManager = HomeKitManager()
        return ScrollView(homeKitManager: homeKitManager,
                          selectedHome: .constant(nil),
                          selectedRoom: .constant(nil),
                          selectedAccessory: .constant(nil),
                          isShakeToToggleEnabled: .constant(false))
    }
}
