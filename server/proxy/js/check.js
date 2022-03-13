const SERVER_LIST_LOCATION = "/etc/nginx/conf.d/js/input.json";
const LAST_UPDATED = "last_update";
const REGISTERED_SERVICE = 'registered_servers';

function check(r) {
    r.log("============================================");
    let res = "false";
    let host = parseHost(r['headersIn']['Authorization']);
    r.log("Host parsed: " + host);
    let allowedServer = getAllowedServerFromFile(r);
    r.log("Allowed servers: " + allowedServer);
    allowedServer.forEach(e => {
        if (e === host) {
            res = "true";
        }
    })
    r.log("============================================");
    return res;
}

function parseHost(header) {
    let res = "";
    header.split(",").forEach(e => {
        if (e.toLowerCase().startsWith("x-matrix origin=")) {
            res = e.toLowerCase().substr(16,)
        }
    });
    return res;

}

function getAllowedServerFromFile() {
    let fs = require("fs");
    const data = fs.readFileSync(SERVER_LIST_LOCATION,
        {encoding: 'utf8', flag: 'r'});
    if (((Date.now() - JSON.parse(data)[LAST_UPDATED]) / 60000) > 1) {
        updateServers()
    }
    return JSON.parse(data)[REGISTERED_SERVICE];
}

function update(r) {
    updateServers();
    r.return(200, "Going to updated serverlist")
}

function updateServers() {
    let fs = require("fs");
    ngx.fetch('http://172.0.0.16:8080/FederationList')
        .then(res => res.json())
        .then(data => {
            data[LAST_UPDATED] = Date.now();
            fs.writeFileSync(SERVER_LIST_LOCATION, JSON.stringify(data));
        });
}


export default {check, update}
