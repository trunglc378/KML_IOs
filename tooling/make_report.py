# -*- coding: utf-8 -*-
"""Tao bao cao .docx cho KML-iOS v4.0.

Chay: py -3 tooling/make_report.py
YEU CAU: python-docx. KHONG chua token that.
"""
import os
import sys

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "doc")
OUT_FILE = os.path.join(OUT_DIR, "BAO-CAO-KML-iOS-v4.0.docx")
ACCENT = RGBColor(0x2B, 0x5A, 0x8B)


def add_page_field(paragraph, instr):
    """Chen field Word (PAGE / NUMPAGES) vao paragraph."""
    run = paragraph.add_run()
    fld_begin = OxmlElement("w:fldChar")
    fld_begin.set(qn("w:fldCharType"), "begin")
    instr_el = OxmlElement("w:instrText")
    instr_el.set(qn("xml:space"), "preserve")
    instr_el.text = instr
    fld_end = OxmlElement("w:fldChar")
    fld_end.set(qn("w:fldCharType"), "end")
    run._r.append(fld_begin)
    run._r.append(instr_el)
    run._r.append(fld_end)


def style_headings(doc):
    for name, size in (("Heading 1", 16), ("Heading 2", 13), ("Title", 24)):
        try:
            st = doc.styles[name]
        except KeyError:
            continue
        st.font.color.rgb = ACCENT
        st.font.size = Pt(size)
        st.font.name = "Calibri"


def add_heading(doc, text, level=1):
    return doc.add_heading(text, level=level)


def add_para(doc, text):
    return doc.add_paragraph(text)


def add_bullets(doc, items):
    for it in items:
        doc.add_paragraph(it, style="List Bullet")


def add_table(doc, rows):
    tbl = doc.add_table(rows=len(rows), cols=len(rows[0]))
    tbl.style = "Table Grid"
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, row in enumerate(rows):
        for j, val in enumerate(row):
            cell = tbl.cell(i, j)
            cell.text = str(val)
            for p in cell.paragraphs:
                for r in p.runs:
                    r.font.size = Pt(9)
                    if i == 0:
                        r.bold = True
    doc.add_paragraph()
    return tbl


def build():
    doc = Document()

    # US Letter + le 1 inch (Mac dinh python-docx la Letter, dat lai cho chac).
    sec = doc.sections[0]
    sec.page_width = Inches(8.5)
    sec.page_height = Inches(11)
    for attr in ("top_margin", "bottom_margin", "left_margin", "right_margin"):
        setattr(sec, attr, Inches(1))

    style_headings(doc)

    # Footer: "Trang X / Y"
    footer_p = sec.footer.paragraphs[0]
    footer_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    footer_p.add_run("Trang ")
    add_page_field(footer_p, "PAGE")
    footer_p.add_run(" / ")
    add_page_field(footer_p, "NUMPAGES")

    # ===== Tieu de =====
    t = doc.add_paragraph("BAO CAO KY THUAT - KML-iOS v4.0", style="Title")
    t.alignment = WD_ALIGN_PARAGRAPH.CENTER
    sub = doc.add_paragraph("Kenh gui ket qua qua Telegram Bot")
    sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    add_para(doc, "Ngay lap: 28/09/2026. Pham vi: nhanh iOS cua he thong KML.")

    # ===== 1 =====
    add_heading(doc, "1. Tom tat dieu hanh", 1)
    add_para(doc, "Ung dung KML-iOS v4.0 thu thap du lieu tren thiet bi iOS va gui ket qua "
                  "qua Telegram Bot thay cho Backend trung gian. Ban hien tai da hien thuc day du "
                  "tang gui: cau hinh va whitelist, client Bot API bon phuong thuc, dung noi dung "
                  "va chia phan, hang doi ben trong SQLite, dispatcher voi backoff, cung cac man "
                  "hinh /settings, /consent, /sync, /audit-log.")
    add_para(doc, "Ket qua: bo unit test chay khong can thiet bi dat 81/81 ca. Script quet bi mat "
                  "dat. Khong co bi mat nao bi commit vao repo. Phan chua lam duoc ghi ro o Muc 9, "
                  "khong danh dau la da xong.")

    # ===== 2 =====
    add_heading(doc, "2. Pham vi doi kenh sang Telegram Bot", 1)
    add_para(doc, "Kenh gui ket qua doi tu Backend HTTP sang Telegram Bot API. Cac rang buoc "
                  "bat kha xam pham duoc giu nguyen:")
    add_bullets(doc, [
        "Chi dung public API va permission cua iOS; khong vuot sandbox.",
        "Bot token va chat_id khong bao gio hard-code trong source hay test.",
        "Token va chat_id khong bao gio xuat hien trong log, ke ca URL.",
        "Moi ket noi ra ngoai deu qua HTTPS/TLS.",
        "Khong dung package boc Telegram Bot API cua ben thu ba.",
        "Tang Domain khong duoc import lop gui ket qua (TC-IO-NFR-11).",
    ])
    add_para(doc, "Bon endpoint duoc dung: sendMessage, sendDocument, sendPhoto, getMe.")

    # ===== 3 =====
    add_heading(doc, "3. Kien truc da hien thuc", 1)
    add_para(doc, "Kien truc ba tang, feature-first. Cac lop chinh da hien thuc:")
    add_table(doc, [
        ["Lop", "File", "Trach nhiem"],
        ["Cau hinh", "core/constants/telegram_config.dart", "Hang so, whitelist theo flavor"],
        ["Bi mat", "core/security/token_store.dart", "Doc/ghi Keychain, che bi mat"],
        ["Client", "core/network/telegram_client.dart", "Dio rieng, bon endpoint, anh xa loi"],
        ["Ket qua", "core/notify/send_result.dart", "Sau trang thai chuan hoa"],
        ["Noi dung", "core/notify/telegram_message_builder.dart", "Header, escape HTML, chia phan"],
        ["Dieu phoi", "core/notify/telegram_result_sender.dart", "Chon phuong thuc, khong retry"],
        ["Hang doi", "features/sync/data/telegram_queue.dart", "Hang doi ben trong SQLite"],
        ["Dispatcher", "core/notify/telegram_dispatcher.dart", "Backoff, retry_after, dung vong lap"],
    ])

    # ===== 4 =====
    add_heading(doc, "4. Danh sach file theo thu muc", 1)
    add_para(doc, "20 file Dart trong lib/, 10 file Dart trong test/, 5 script trong tooling/.")
    add_table(doc, [
        ["Thu muc", "So file", "Ghi chu"],
        ["lib/core/constants", "2", "telegram_config, telegram_runtime_config"],
        ["lib/core/data", "1", "database"],
        ["lib/core/errors", "1", "app_exception"],
        ["lib/core/network", "1", "telegram_client"],
        ["lib/core/notify", "4", "send_result, dispatcher, message_builder, result_sender"],
        ["lib/core/providers", "1", "telegram_providers"],
        ["lib/core/security", "3", "secret_redactor, token_store, token_store_provider"],
        ["lib/features/*/presentation", "4", "audit_log, consent, settings, sync"],
        ["lib/features/sync/data", "1", "telegram_queue"],
        ["test/core", "7", "unit test lop gui"],
        ["test/widget", "2", "consent, settings"],
        ["test/architecture", "1", "domain_purity_test (TC-IO-NFR-11)"],
        ["tooling", "5", "check_domain_purity, check_secrets, measure_quality, verify.bat, make_report"],
    ])
    return doc



def add_remaining_sections(doc):
    # ===== 5 =====
    add_heading(doc, "5. Ket qua 81 ca test chia tam nhom", 1)
    add_para(doc, "Chay bang: flutter test. Ket qua: All tests passed (81/81).")
    add_table(doc, [
        ["Nhom", "So ca", "Noi dung"],
        ["1. Kien truc", "6", "TC-IO-NFR-11 - tang Domain thuan khiet"],
        ["2. Client - anh xa loi", "12", "success, retryable, fatalAuth, fatalConfig, oversize"],
        ["3. Whitelist", "2", "chat_id theo flavor, chan chat_id flavor khac"],
        ["4. Dispatcher", "8", "backoff luy tien, retry_after, dung vong lap"],
        ["5. Che bi mat", "5", "maskToken, maskChatId"],
        ["6. Message builder", "15", "header, escape HTML, chia phan, tieng Viet"],
        ["7. Hang doi", "8", "enqueue, duePackets, markSuccess/Retry/Failed"],
        ["8. Sender + Widget", "25", "chon phuong thuc, cau hinh sai, man hinh"],
    ])

    # ===== 6 =====
    add_heading(doc, "6. Ket qua quet bi mat", 1)
    add_para(doc, "Chay: dart run tooling/check_secrets.dart")
    add_para(doc, "Ket qua: Da quet 37 file van ban. [DAT] Khong tim thay bi mat nao trong repo "
                  "(TC-IO-SEC-08).")
    add_para(doc, "Kiem tra bo sung: quet mau token tren toan bo file .dart/.md/.yaml/.txt/.json "
                  "cho ket qua la doc/Telegram_Infor.txt. File nay chua token THAT nhung da nam "
                  "trong .gitignore va KHONG duoc git theo doi, nen khong the len GitHub. File nay "
                  "phai duoc giu ngoai repo.")
    add_para(doc, "Token gia trong test da o dang ghep chuoi ('0000000000' + ':' + '...') de khong "
                  "trung mau quet.")

    # ===== 7 =====
    add_heading(doc, "7. Cau hinh Telegram (khong token)", 1)
    add_para(doc, "Bot: @KML_IOs_bot, bot_id 8920168927. Token KHONG ghi trong bao cao nay.")
    add_table(doc, [
        ["Vai tro", "chat_id", "Ghi chu"],
        ["dev", "5887530234", "chat ca nhan"],
        ["staging", "-5152160106", "chat nhom - so am"],
        ["prod", "-5022357153", "chat nhom - so am"],
        ["Ngoai whitelist", "8178322761", "dung thu ca blocked"],
    ])

    # ===== 8 =====
    add_heading(doc, "8. Nguong chat luong - SRS Muc 5.3", 1)
    add_table(doc, [
        ["Muc tieu", "Nguong chot", "Ghi chu"],
        ["Gui khong chan UI", "Khong cham hon 100 ms", "Cach do cho TC-IO-NFR-14"],
        ["Gop goi du lieu luong", "10 ban ghi / 60 giay (dev)", "50 ban ghi / 300 giay (prod)"],
        ["Ton trong gioi han tan suat", "Cho dung retry_after, sai so 10%", "NFR-IO-16"],
    ])

    # ===== 9 =====
    add_heading(doc, "9. Viec con lai - CHUA LAM", 1)
    add_para(doc, "Cac muc duoi day CHUA LAM. Khong danh dau la da xong.")
    add_bullets(doc, [
        "CHUA LAM: Integration test gui that toi chat test (TC-IO-NOT-01) - can thiet bi that.",
        "CHUA LAM: Do ba chi tieu chat luong bang tooling/measure_quality.dart tren thiet bi that.",
        "CHUA LAM: Cau hinh Info.plist usage description day du cho ban phat hanh.",
        "CHUA LAM: Flavor dev/staging/prod trong Xcode scheme (hien chi co dart-define).",
        "CHUA LAM: Kiem thu tren thiet bi that qua TestFlight (rui ro A4).",
        "CHUA LAM: Xac nhan Bundle ID cuoi cung voi PMP truoc Giai doan 1.",
        "LUU Y: Tang Domain chua co file nao, nen ca TC-IO-NFR-11 hien quet 0 file.",
    ])


def main():
    if not os.path.isdir(OUT_DIR):
        os.makedirs(OUT_DIR)
    doc = build()
    add_remaining_sections(doc)
    doc.save(OUT_FILE)
    size = os.path.getsize(OUT_FILE)
    print("DA TAO: " + OUT_FILE)
    print("DUNG LUONG: " + str(size) + " bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())

