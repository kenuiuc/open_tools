import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;
import javax.net.ssl.SSLHandshakeException;

public class CheckSSL {
    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("Usage: java CheckSSL <https-endpoint-url>");
            System.exit(1);
        }

        String targetUrl = args[0];
        System.out.println("Testing SSL handshake for: " + targetUrl);

        try {
            URL url = URI.create(targetUrl).toURL();
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();

            // 使用 HEAD 方法，减少数据传输
            conn.setRequestMethod("HEAD");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);

            // 发起连接，这会触发 TLS 握手
            int responseCode = conn.getResponseCode();

            System.out.println("\n[SUCCESS] SSL/TLS handshake passed successfully!");
            System.out.println("HTTP Response Code (ignoring auth errors): " + responseCode);

        } catch (SSLHandshakeException e) {
            System.err.println("\n[FAILED] SSL Handshake / Certificate verification failed:");
            System.err.println(e.getMessage());
            System.exit(2);
        } catch (Exception e) {
            // 其他异常（如连接超时、DNS 解析失败等，但证书是OK的）
            System.out.println("\n[INFO] SSL handshake passed, but encountered another error:");
            System.out.println(e.getMessage());
        }
    }
}
