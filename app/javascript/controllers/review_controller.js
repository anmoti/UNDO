import { Controller } from "@hotwired/stimulus";

export default class extends Controller {

    udon_score = 5;

    //スターの動的生成をする
    connect() {
        const starsContainer = document.getElementById('stars');
        if (!starsContainer) return;

        for (let i = 0; i < 5; i++) {
            const Button = document.createElement('button');
            Button.className = "left-buttons";

            const Img = document.createElement('img');
            Img.className = "star-image";
            Img.src = "star-yellow.png";
            Img.style.width = "40px";
            Img.style.height = "auto";
            Img.id = `star_img_${i}`;
            Button.appendChild(Img);
            Button.style.backgroundColor = "transparent";
            Button.style.paddingRight = "8px";

            Button.type = "button";

            Button.onclick = () => this.click_star(i + 1);

            starsContainer.appendChild(Button);
        }
    }

    /**
     * スターがクリックされた時の処理
    */
    click_star(score) {
        for (let i = 1; i < 5; i++) {
            const shine_star = document.getElementById(`star_img_${i}`);
            if (shine_star instanceof HTMLImageElement) {
                shine_star.src = score > i ? "star-yellow.png" : "star-black.png";
            }
        }
        this.udon_score = score;
    }

    /**
     * 送信確認時のスターの動的生成
     */
    check_show() {
        document.getElementById('check-ground').style.display = 'flex';
        const starsContainer = document.getElementById('check-star');
        if (!starsContainer) return;

        for (let i = 0; i < this.udon_score; i++) {
            const star_img = document.createElement('img');
            star_img.src = "star-yellow.png";
            star_img.style.width = "20px";
            star_img.style.height = "auto";
            star_img.id = `check-star-${i}`;
            starsContainer.appendChild(star_img);
        }
        for (let i = this.udon_score; i < 5; i++) {
            const star_img = document.createElement('img');
            star_img.src = "star-p.png";
            star_img.style.width = "20px";
            star_img.style.height = "auto";
            star_img.id = `check-star-${i}`;
            starsContainer.appendChild(star_img);
        }
        const commentElement = document.getElementById('comment');
        const commentValue = commentElement instanceof HTMLInputElement || commentElement instanceof HTMLTextAreaElement
            ? commentElement.value
            : '';
        document.getElementById('comment-check').innerText = "コメント: " + commentValue;
    }

    /**
     * コメント送信ボタン押下時の処理
     */
    submit_comment() {
        document.getElementById('logout-background').style.display = 'none';
        //TODO: コメントの送信処理
    }

    /**
     * コメント表示画面のキャンセルボタン押下時の処理
     */
    comment_cancel() {
        document.getElementById('logout-background').style.display = 'none';
    }

    /**
     * 送信確認画面のキャンセルボタン押下時の処理
     */
    cancel_comment() {
        document.getElementById('check-ground').style.display = 'none';
        for (let i = 0; i < 5; i++) {
            const star_img = document.getElementById(`check-star-${i}`);
            if (star_img) {
                star_img.remove();
            }
        }
    }

    /**
     * 測定方法の表示
     */
    howto_show() {
        document.getElementById('howto-bod-background').style.display = 'none';
    }
}