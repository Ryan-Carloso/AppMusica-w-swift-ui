import SwiftUI
import AVKit
import XCDYouTubeKit

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
    @State private var player: AVPlayer? = nil

    var body: some View {
        VStack(spacing: 16) {
            TextField("Insira o nome do vídeo", text: $videoTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Pesquisar Vídeo") {
                searchForVideo(title: videoTitle)
            }
            .padding()

            // Player invisível
            if selectedVideo != nil {
                VideoPlayer(player: player)
                    .frame(height: 0) // Dimensões zero para esconder
                    .onAppear {
                        playVideo(url: selectedVideo!)
                    }
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
                            playVideo(url: video.url)
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
    
    private func playVideo(url: String) {
        let videoId = url.components(separatedBy: "v=").last ?? ""
        XCDYouTubeClient.default().getVideoWithIdentifier(videoId) { (video, error) in
            if let error = error {
                print("Erro ao obter vídeo: \(error)")
                return
            }
            
            guard let streamURLs = video?.streamURLs else {
                print("Nenhuma URL de stream disponível.")
                return
            }

            // Seleciona a melhor qualidade disponível
            let preferredQualities: [XCDYouTubeVideoQuality] = [ .HD1080, .HD720]
            var streamURL: URL? = nil
            
            for quality in preferredQualities {
                if let url = streamURLs[quality] {
                    streamURL = url
                    break
                }
            }

            guard let finalStreamURL = streamURL else {
                print("Nenhuma URL de stream disponível nas qualidades preferidas.")
                return
            }

            player = AVPlayer(url: finalStreamURL)
            player?.play()
        }
    }
}

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
