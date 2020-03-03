<img align="left" src="https://i.redd.it/1cp00o73bquz.jpg" width="140px">

## Who picks Yasuo faster than me?
Some code that helps you **pick your favorite champion as _quick as lightning_**!

<br>

## Tools

![](https://img.shields.io/badge/prebuilt%20binary-not%20yet-brightgreen)
<br>
![](https://img.shields.io/badge/how%20to%20build-from%20source-blue)

### # [yasuoit](https://github.com/nomi-san/yasuo/tree/master/yasuoit)
- Written in AutoIt
- Help you how to use LCU API

### # [yasharp](https://github.com/nomi-san/yasuo/tree/master/yasharp)
- Written in **C#**
- Use websocket for event listener
- Talk to the system via chat box

## Play on web browser with JavaScript

### Prepare

- Please make sure **League Client** is opened.
- A web browser (e.g **Chrome**, **Opera** or **FireFox**).

### Take action

**1**. Open your terminal and type:

- On Windows (use **cmd**, administrator is required)
  ```batch
  WMIC PROCESS WHERE name='LeagueClientUx.exe' GET commandline
  ```

- On MacOS
  ```bash
  ps x -o args | grep 'LeagueClientUx'
  ```

**2**. Look for the following line
```
"--remoting-auth-token=abcdef123456ABCDEF123456" "--app-port=56789"
```
- `abcdef123456ABCDEF123456` is the auth key.
- `56789` is the address port.

**3**. Open your browser, enter the URL:
```http
https://127.0.0.1:PORT/lol-champions/v1/owned-champions-minimal
```
- Replace **PORT** by your port.
- After the login dialog shown, enter "**riot**" as username and your auth key as password.

The browser will show all your owned and free champions (as JSON), please find ID of your favorite champions. Use **Ctrl** + **F** with  keyword:
```
"name":"champion_name_here
```

**4**. On this tab, open **console** (on Windows, press **Ctrl** + **Shift** + **J** with **Chrome**)

Enter the code below (or copy code in [original.js](https://github.com/nomi-san/yasuo/blob/master/original.js) if **ES6** is supported):
```js
var start=function(){var t,n=arguments.length>0&&void 0!==arguments[0]?arguments[0]:[157],a=async function(t,n,a){return await fetch(n,{method:t,body:a,headers:{"Content-type":"application/json; charset=UTF-8"}}).then(function(t){return t.text()}).then(function(t){return JSON.parse(t.length?t:"{}")})},e=async function(t,n){return 0===Object.keys(await a("PATCH","/lol-champ-select/v1/session/actions/".concat(t),JSON.stringify({championId:n}))).length},c=setInterval(async function(){if(await async function(){return"InProgress"===(await a("GET","/lol-matchmaking/v1/ready-check")).state}())await async function(){return await a("POST","/lol-matchmaking/v1/ready-check/accept")}();else if((t=await async function(){var t=await a("GET","/lol-champ-select/v1/session"),n=t.localPlayerCellId,e=t.actions;return e?e[0].filter(function(t){return t.actorCellId===n})[0].id:-1}())>-1){for(var i=0;i<n.length&&!await e(t,n[i]);i++);await async function(t){return await a("POST","/lol-champ-select/v1/session/actions/".concat(t,"/complete"))}(t),clearInterval(c)}},250)};
```

**5**. Call `start` function, the first arg is champion ID array, e.g
```js
start([157, 10, 1]); // Yasuo, Kayle, Annie
```

**6**. Make a **Practice** or a **Custom**/**Normal** game (Summoner's Rift - blind pick only), and enjoy!
