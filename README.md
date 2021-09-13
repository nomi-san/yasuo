<img align="left" src="https://i.redd.it/1cp00o73bquz.jpg" width="140px">

## Who picks Yasuo faster than me?
Some code that helps you **pick and lock Yasuo or any champion as _quick as lightning_**!

<br>

You can read the Vietnamese post <a href="https://nomi.dev/posts/super-fast-pick-lock" target="_blank">here</a> 😀

## Some tools

### / [yasuoit](https://github.com/nomi-san/yasuo/tree/master/yasuoit)
- Written in **AutoIt**
- Help you how to use LCU API

### / [yasharp](https://github.com/nomi-san/yasuo/tree/master/yasharp)
- Written in **C#**
- Using websocket for event listener
- Talk to the system via League's chatbox

## 4 steps to pick and lock Yasuo immediately on your web browser!

### Preparing

- Please make sure **League Client** is opened
- A modern web browser, Chromium-based web browser is suggested

### Step 1 - Get League's auth

Open your terminal and type:

- On Windows (use **cmd**, run as admin)
  ```batch
  WMIC PROCESS WHERE name='LeagueClientUx.exe' GET commandline
  ```

- On MacOS
  ```bash
  ps x -o args | grep 'LeagueClientUx'
  ```

Look for the following line:
```
"--remoting-auth-token=abcdef123456ABCDEF123456" "--app-port=56789"
```
- `abcdef123456ABCDEF123456` is the auth token (**PASS**)
- `56789` is the address port (**PORT**)

### Step 2 - Login and get champion IDs

Open your web browser and enter this URL:
```http
https://127.0.0.1:PORT/lol-champions/v1/owned-champions-minimal
```
- Replace **PORT** by your port, press enter
- The login dialog will be shown, enter "**riot**" as username and your auth token as password

The browser will show all your owned and free champions (as JSON), please find ID of your favorite champions. Use **Ctrl** + **F** with  keyword:
```
"name":"champion_name_here
```

### Step 3 - Execute script

On this tab, open **console** (on Windows, press <kbd>Ctrl Shift J</kbd> on **Chrome**)

Copy the code below (or from [script.js](/script.js)) and paste to the console:
```js
var start=function(){var t,n=arguments.length>0&&void 0!==arguments[0]?arguments[0]:[157],a=async function(t,n,a){return await fetch(n,{method:t,body:a,headers:{"Content-type":"application/json; charset=UTF-8"}}).then(function(t){return t.text()}).then(function(t){return JSON.parse(t.length?t:"{}")})},e=async function(t,n){return 0===Object.keys(await a("PATCH","/lol-champ-select/v1/session/actions/".concat(t),JSON.stringify({championId:n}))).length},c=setInterval(async function(){if(await async function(){return"InProgress"===(await a("GET","/lol-matchmaking/v1/ready-check")).state}())await async function(){return await a("POST","/lol-matchmaking/v1/ready-check/accept")}();else if((t=await async function(){var t=await a("GET","/lol-champ-select/v1/session"),n=t.localPlayerCellId,e=t.actions;return e?e[0].filter(function(t){return t.actorCellId===n})[0].id:-1}())>-1){for(var i=0;i<n.length&&!await e(t,n[i]);i++);await async function(t){return await a("POST","/lol-champ-select/v1/session/actions/".concat(t,"/complete"))}(t),clearInterval(c)}},250)};
```

Press enter to run the script.

Next, execute the code below:
```js
start([157, 10, 1]) // Yasuo, Kayle, Annie
```
- Put it to console and enter
- Some bad requests (404) may be shown, don't worry 😎

### Step 4 - Enjoy

Make a Custom/Normal game (Summoner's Rift - blind pick only), and enjoy!
