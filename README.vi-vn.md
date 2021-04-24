<img align="left" src="https://i.redd.it/1cp00o73bquz.jpg" width="140px">

## Thằng chó nào pick Yasuo nhanh hơn tao?
Một chút code phê cần giúp bạn pick tướng nhanh như chớp!

<br>

### Bạn có thể đọc bài viết chi tiết <a href="https://nomi.dev/posts/super-fast-pick-lock" target="_blank">tại đây</a> 😀

## Một số tool

### / [yasuoit](https://github.com/nomi-san/yasuo/tree/master/yasuoit)
- Viết bằng **AutoIt**
- Hướng dẫn bạn sử dụng LCU API

### / [yasharp](https://github.com/nomi-san/yasuo/tree/master/yasharp)
- Viết b **C#**
- Bắt các LCU event thông qua websocket
- Giao tiếp với hệ thống thông qua chat box

## Quẩy trên trình duyệt với JavaScript

Chỉ với vài bước đơn giản là có thể tự động chấp nhận trận đấu và pick tướng nhanh đến chóng mặt.

### Chuẩn bị

- **Leadgue Client** đã được bật sẵn
- Một trình duyệt web như Chrome, CốcCốc, FireFox, Opera... phiên bản mới nhất (nói không với IE nha)

### Hành động

**Bước 1**

Mở console/terminal và gõ lệnh sau:
- Trên Windows (sử dụng **cmd**, phải có quyền admin)
  ```batch
  WMIC PROCESS WHERE name='LeagueClientUx.exe' GET commandline
  ```

- Trên MacOS
  ```bash
  ps x -o args | grep 'LeagueClientUx'
  ```
  
Nhấn enter để thực thi lệnh.

**Bước 2**

Tìm dòng sau trên terminal
```
"--remoting-auth-token=abcdef123456ABCDEF123456" "--app-port=56789"
```

Trong đó:
- `abcdef123456ABCDEF123456` key xác thực (password)
- `56789` là cổng kết nối (port)

**Bước 3**

Mở trình duyệt web và gõ URL:
```http
https://127.0.0.1:PORT/lol-champions/v1/owned-champions-minimal
```
- Thay **PORT** bằng port tìm được ở trên

Nhấn enter để truy cập vào URL.

Sẽ có hộp thoại đăng nhập hiện ra
- Tên đăng nhập là "**riot**"
- Mật khẩu là cái password tìm được ở trên

Sau khi đăng nhập thành công, trình duyệt sẽ hiện ra JSON data chứa toàn bộ tướng đã sở hữu.

Nhấn Ctrl + F để tìm ID của tướng cần pick theo format:
```
"name":"<tên tướng>
```

> ID của Yasuo là 157, Kayle là 10, Annie là 1...

**Bước 4**

Mở console trong tab đăng nhập lúc nãy (trên Windows, nhấn **Ctrl**+**Shift**+**J** nếu dùng **Chrome**)

Dán đoạn code sau vào (hoặc copy code trong file [script.js](script.js)):
```js
var start=function(){var t,n=arguments.length>0&&void 0!==arguments[0]?arguments[0]:[157],a=async function(t,n,a){return await fetch(n,{method:t,body:a,headers:{"Content-type":"application/json; charset=UTF-8"}}).then(function(t){return t.text()}).then(function(t){return JSON.parse(t.length?t:"{}")})},e=async function(t,n){return 0===Object.keys(await a("PATCH","/lol-champ-select/v1/session/actions/".concat(t),JSON.stringify({championId:n}))).length},c=setInterval(async function(){if(await async function(){return"InProgress"===(await a("GET","/lol-matchmaking/v1/ready-check")).state}())await async function(){return await a("POST","/lol-matchmaking/v1/ready-check/accept")}();else if((t=await async function(){var t=await a("GET","/lol-champ-select/v1/session"),n=t.localPlayerCellId,e=t.actions;return e?e[0].filter(function(t){return t.actorCellId===n})[0].id:-1}())>-1){for(var i=0;i<n.length&&!await e(t,n[i]);i++);await async function(t){return await a("POST","/lol-champ-select/v1/session/actions/".concat(t,"/complete"))}(t),clearInterval(c)}},250)};
```

**Bước 5**

Gọi hàm `start` và truyền vào một mảng ID của các tướng
```js
start([157, 10, 1]) // Yasuo, Kayle, Annie
```
- Cho vào console và enter
- Sẽ có một số báo lỗi đỏ (do bad request) hiện ra, không cần quan tâm

**Bước 6**

Tạo một trận Phòng tập hoặc Đánh thường và thưởng thức.

> Đối với rank thì chỉ hỗ trợ auto chấp nhận trận đấu thôi nhé!
