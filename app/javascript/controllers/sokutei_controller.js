import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    /**
   * BOD/COD測定の手順表示
  */
    bod_howto() {
        document.getElementById('howto-bod-background').style.display = 'flex';
    }

    /**
     * 注意事項表示
    */
    careful_show() {
        document.getElementById('back-root').style.display = 'none';
        document.getElementById('careful_view').style.display = 'block';
        setTimeout(this.bod_show, 5000);
    }

    /**
     * BOD/COD値表示
    */
    bod_show() {
        document.getElementById('bod-cod-exp').style.display = 'block';
        document.getElementById('careful_view').style.display = 'none';
        document.getElementById('do_undo').style.display = 'inline-block';
        document.getElementById('bod_value').innerText = `3900[mg/L]`;
        document.getElementById('cod_value').innerText = `2100[mg/L]`;
        document.getElementById('turbidity_value').innerText = `691.2`;
        document.getElementById('logout-surundana').innerText = "測定結果";
        document.getElementById('explains').style.display = "none";
        //document.getElementById('bod-cod-show').style.display = 'block'; --- IGNORE ---
    }
}
