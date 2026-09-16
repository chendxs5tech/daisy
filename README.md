# daisy — database chung của DX team

`daisy` là **database dùng chung của DX team**: một chỗ duy nhất, tên gọi thống nhất, để
cả team cùng đọc và ghi dữ liệu của mình — thay vì mỗi người giữ một bản riêng rồi số
liệu lệch nhau.

Thư mục này chứa toàn bộ phần dựng `daisy`: một **PostgreSQL 15.12 chạy bằng Docker
Compose**, tự nạp schema ở lần khởi động đầu tiên. Chỉ có một service duy nhất là
`postgres`, không có gì khác để phải bảo trì. Version được ghim cố định để máy ai chạy
cũng ra đúng một phiên bản.

> Phần "dùng vào việc cụ thể gì" — những bảng nào, ai ghi vào, dữ liệu lấy từ đâu — chưa
> được viết. Khi team chốt xong thì bổ sung vào đây.

## Quy ước tên

Mọi thứ đều mang chữ `daisy` để nhìn là biết ngay thuộc về đâu: project `daisy`, image
`daisy-postgres:15.12`, container `daisy-postgres`, volume `daisy-postgres-data`, user
`daisy`, database `daisy_db`. Thêm gì mới thì giữ đúng quy ước này.

## Cấu trúc

| File | Vai trò |
| --- | --- |
| [compose.yml](compose.yml) | Định nghĩa service `postgres` |
| [Dockerfile](Dockerfile) | Image Postgres custom: timezone + copy script initdb |
| [.env.example](.env.example) | Mẫu biến môi trường, copy thành `.env` |
| [initdb/01-init.sql](initdb/01-init.sql) | Bảng `test_demo` + 2 dòng dữ liệu mẫu |
| `data/` | Dữ liệu Postgres, Docker tự tạo ở lần chạy đầu. Không commit |

## Chạy

```bash
cp .env.example .env      # rồi sửa POSTGRES_PASSWORD
docker compose up -d --build
docker compose ps         # chờ tới khi state là "healthy"
```

## Kết nối

```
postgresql://daisy:<POSTGRES_PASSWORD>@localhost:5432/daisy_db
```

Vào psql trong container:

```bash
docker compose exec postgres psql -U daisy -d daisy_db
```

Kiểm tra nhanh là chạy được:

```bash
docker compose exec postgres psql -U daisy -d daisy_db -c 'select * from test_demo;'
```

## Lệnh thường dùng

```bash
docker compose logs -f postgres        # xem log
docker compose restart postgres        # restart
docker compose down                    # dừng, GIỮ dữ liệu
rm -rf ./data                          # XOÁ sạch dữ liệu (chạy sau khi đã down)
```

Backup / restore:

```bash
mkdir -p backups
docker compose exec -T postgres pg_dump -U daisy -d daisy_db -Fc > backups/daisy.dump
docker compose exec -T postgres pg_restore -U daisy -d daisy_db --clean < backups/daisy.dump
```

## Lưu ý

- **Cấu hình hiện tại chưa dùng chung được thật.** Compose map port ra `localhost` của
  máy chạy nó và dữ liệu nằm ở volume cục bộ, nên mỗi người tự `docker compose up` sẽ có
  một bản `daisy` riêng, dữ liệu không thấy nhau. Muốn chung thật thì phải dựng trên
  **một** máy cả team nối tới được, mở port cho mạng nội bộ chứ không chỉ `localhost`, và
  cấp user riêng cho từng người thay vì dùng chung user `daisy`. Chưa làm phần đó.
- **Bắt buộc phải có file `.env`.** `compose.yml` khai báo `env_file: .env` (không đặt
  `optional: true`), nên thiếu file là Compose báo lỗi ngay chứ không chạy với giá trị
  mặc định ẩn. `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` đi thẳng từ `.env` vào
  container; `POSTGRES_PORT` do chính Compose nội suy và cũng báo lỗi nếu chưa khai báo.
- **Dự án đặt ở `/opt/daisy` trên VM.** Bind mount trong `compose.yml` viết bằng đường dẫn
  tương đối (`./data`) nên không phụ thuộc vị trí này — Compose tính tương đối từ chỗ đặt
  `compose.yml`. Đặt ở `/opt/daisy` thì dữ liệu ra `/opt/daisy/data/pgdata`.
- **Dữ liệu nằm ngay trong thư mục dự án**, ở `./data/pgdata`, bằng bind mount chứ không
  phải named volume. Nhìn thấy và backup được bằng đường dẫn thật trên máy. Hệ quả:
  `docker compose down -v` **không** xoá dữ liệu nữa (cờ `-v` chỉ xoá named volume), muốn
  xoá sạch thì phải tự xoá thư mục `./data`.
- `data/` đã được thêm vào `.gitignore` và `.dockerignore`. Bắt buộc phải có: thiếu dòng
  trong `.gitignore` là commit cả database, thiếu trong `.dockerignore` là mỗi lần
  `--build` phải copy cả database vào build context.
- Script trong `initdb/` **chỉ chạy một lần**, khi `./data` còn rỗng. Sửa schema sau đó
  thì phải apply bằng migration, hoặc reset sạch bằng
  `docker compose down && rm -rf ./data && docker compose up -d --build`.
- `initdb/` cố ý để đơn giản: một bảng `test_demo` và 2 dòng mẫu, không extension, không
  schema riêng, không trigger.
- Timezone trong container là `Asia/Ho_Chi_Minh`, đặt trong [Dockerfile](Dockerfile).
