import SwiftUI
import WebKit

struct Video: Identifiable {
    let id = UUID()
    let title: String
    let url: String
}

struct ContentView: View {
    @State private var videoTitle: String = ""
    @State private var searchResults: [Video] = []
    @State private var selectedVideo: String? = nil
    @State private var savedVideos: [Video] = []

    var body: some View {
        VStack(spacing: 16) {
            TextField("Insira o nome do vídeo", text: $videoTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Pesquisar Vídeo") {
                searchForVideo(title: videoTitle)
            }
            .padding()

            if let selectedVideo = selectedVideo {
                VideoPlayerView(videoURL: selectedVideo)
                    .frame(height: 300)
                    .padding(.top)
            }

            List {
                ForEach(searchResults) { video in
                    HStack {
                        Text(video.title)
                        Spacer()
                        Button("Salvar") {
                            saveVideo(video: video)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }

            Divider()

            Text("Playlist")
                .font(.headline)

            List {
                ForEach(savedVideos) { video in
                    HStack {
                        Text(video.title)
                        Spacer()
                        Button("Assistir") {
                            selectedVideo = video.url
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
    }

    private func searchForVideo(title: String) {
        let apiKey = "AIzaSyAlgVcxt61CGYaWsXE6OHguyuG99o0xo2c" // Coloque sua chave da API aqui
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=5&q=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Erro ao buscar vídeos: \(error)")
                return
            }
            
            guard let data = data else { return }
            do {
                let json = try JSONDecoder().decode(YouTubeResponse.self, from: data)
                DispatchQueue.main.async {
                    searchResults = json.items.map { item in
                        Video(title: item.snippet.title, url: "https://www.youtube.com/watch?v=\(item.id.videoId)")
                    }
                }
            } catch {
                print("Erro ao decodificar dados: \(error)")
            }
        }.resume()
    }

    private func saveVideo(video: Video) {
        if !savedVideos.contains(where: { $0.title == video.title }) {
            savedVideos.append(video)
        }
    }
}

struct VideoPlayerView: UIViewRepresentable {
    let videoURL: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: videoURL) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
}

// Estrutura para decodificar a resposta da API
struct YouTubeResponse: Codable {
    let items: [Item]
    
    struct Item: Codable {
        let id: ID
        let snippet: Snippet
        
        struct ID: Codable {
            let videoId: String
        }
        
        struct Snippet: Codable {
            let title: String
        }
    }
}

@main
struct YouTubeSearchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
