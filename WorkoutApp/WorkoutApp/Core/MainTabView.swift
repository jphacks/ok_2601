
import SwiftUI

struct MainTabView: View {
    @StateObject private var workoutStore = WorkoutStore()
    
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("ホーム", systemImage: "house")
            }

            NavigationStack {
                RecordView()
            }
            .tabItem {
                Label("記録", systemImage: "list.clipboard")
            }

            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("カレンダー", systemImage: "calendar")
            }

            NavigationStack {
                EvolutionView()
            }
            .tabItem {
                Label("変化", systemImage: "chart.line.uptrend.xyaxis")
            }

            NavigationStack {
                GachaView()
            }
            .tabItem {
                Label("ガチャ", systemImage: "sparkles")
            }            
        }
        .environmentObject(workoutStore)
    }
}
