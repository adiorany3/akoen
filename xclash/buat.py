import yaml

# Baca file ambil4.yaml
with open('ambil4.yaml', 'r') as file:
    data = yaml.safe_load(file)

# Ubah server dengan IP yang diberikan
new_servers = ['172.67.5.14', '172.66.0.145', '104.22.5.240', '104.17.72.206', '104.17.155.243']

# Pastikan data adalah dictionary (format Clash)
if isinstance(data, list):
    proxies = data
    data = {
        'proxies': proxies,
        'proxy-groups': []
    }
elif isinstance(data, dict):
    if 'proxies' not in data:
        data['proxies'] = []
    if 'proxy-groups' not in data:
        data['proxy-groups'] = []
else:
    print("Format file tidak didukung")
    exit(1)

# Update server untuk setiap proxy secara berurutan
for i, proxy in enumerate(data['proxies']):
    if 'server' in proxy:
        proxy['server'] = new_servers[i % len(new_servers)]  # Menggunakan server secara berurutan

# Dapatkan semua nama proxy
proxy_names = [proxy.get('name') for proxy in data['proxies'] if 'name' in proxy]

# Buat grup proxy
proxy_groups = [
    {
        'name': 'URL-TEST',
        'type': 'url-test',
        'proxies': proxy_names,
        'url': 'http://www.gstatic.com/generate_204',
        'interval': 300
    },
    {
        'name': 'LOADBALANCE',
        'type': 'load-balance',
        'proxies': proxy_names,
        'url': 'http://www.gstatic.com/generate_204',
        'interval': 300
    },
    {
        'name': 'FAILOVER',
        'type': 'fallback',
        'proxies': proxy_names,
        'url': 'http://www.gstatic.com/generate_204',
        'interval': 300
    }
]

# Tambahkan grup proxy baru
data['proxy-groups'] = proxy_groups

# Simpan hasil ke ILnew.yaml
with open('ILnew.yaml', 'w') as file:
    yaml.dump(data, file, sort_keys=False)

print("File ILnew.yaml berhasil dibuat dengan proxy group URL-TEST, LOADBALANCE, dan FAILOVER.")