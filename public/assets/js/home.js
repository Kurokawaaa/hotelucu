let selectedRating = 0;
let homeSwiper = null;
let homeFlatpickr = null;
const homeCommentsStorageKey = "home-comments";
const defaultComments = [
  {
    name: "andi",
    text: "Hotelnya nyaman banget dan pelayanannya ramah!",
    rating: 5,
    time: "10 Apr 2026, 09.00"
  }
];

function initHomePage() {
  const root = document.querySelector(".hero-section");
  if (!root) return;
  if (root.dataset.homeInitialized === "true") return;

  root.dataset.homeInitialized = "true";

  const navbar = document.querySelector(".hotel-navbar");
  if (navbar) {
    window.addEventListener("scroll", () => {
      navbar.classList.toggle("scrolled", window.scrollY > 50);
    });
  }

  const dateInput = document.getElementById("dateInput");
  if (dateInput && typeof flatpickr !== "undefined") {
    homeFlatpickr = flatpickr(dateInput, {
      mode: "range",
      minDate: "today",
      dateFormat: "d M Y",
      locale: {
        rangeSeparator: " - "
      },
      appendTo: document.getElementById("datePopup"),
      static: true,
      onOpen: function (_selectedDates, _dateSt, instance) {
        instance.calendarContainer.classList.add("slide-up");
      }
    });
  }

  function closeAllPopups() {
    document.querySelectorAll(".popup").forEach((popup) => {
      popup.classList.remove("active");
    });
  }

  function togglePopup(popup) {
    const isOpen = popup.classList.contains("active");
    closeAllPopups();
    if (!isOpen) popup.classList.add("active");
  }

  document.querySelectorAll(".search-card").forEach((card) => {
    card.addEventListener("click", (event) => {
      event.stopPropagation();

      if (card.id === "dateToggle" && homeFlatpickr) {
        closeAllPopups();
        homeFlatpickr.open();
        return;
      }

      const popup = card.querySelector(".popup");
      if (popup) togglePopup(popup);
    });
  });

  document.addEventListener("click", () => {
    closeAllPopups();
    if (homeFlatpickr) homeFlatpickr.close();
  });

  const roomValue = document.getElementById("roomValue");
  document.querySelectorAll(".room-options li").forEach((item) => {
    item.addEventListener("click", (event) => {
      event.stopPropagation();
      roomValue.innerText = item.dataset.value;
      closeAllPopups();
    });
  });

  let adult = 2;
  let child = 0;
  let room = 1;

  const adultCount = document.getElementById("adultCount");
  const childCount = document.getElementById("childCount");
  const roomCount = document.getElementById("roomCount");
  const guestValue = document.getElementById("guestValue");

  function calculateMinRoom(currentAdult, currentChild) {
    let roomFromAdult = Math.ceil(currentAdult / 2);
    let leftoverAdult = currentAdult % 2;
    let remainingChild = currentChild;

    if (leftoverAdult === 1 && remainingChild > 0) {
      remainingChild -= 1;
    }

    let roomFromChild = Math.ceil(remainingChild / 2);
    let totalRoom = roomFromAdult + roomFromChild;

    if (totalRoom < 1) totalRoom = 1;
    if (totalRoom > 10) totalRoom = 10;

    return totalRoom;
  }

  function updateGuestText() {
    if (!adultCount || !childCount || !roomCount || !guestValue) return;

    const minRoom = calculateMinRoom(adult, child);

    if (room < minRoom) room = minRoom;
    if (room > 10) room = 10;

    adultCount.innerText = adult;
    childCount.innerText = child;
    roomCount.innerText = room;
    guestValue.innerText = `${adult} Orang, ${child} Anak, ${room} Kamar`;
  }

  document.querySelectorAll(".plus, .minus").forEach((button) => {
    button.addEventListener("click", (event) => {
      event.stopPropagation();

      const type = button.dataset.type;
      const isPlus = button.classList.contains("plus");

      if (type === "adult") {
        if (isPlus && adult < 10) adult += 1;
        if (!isPlus && adult > 1) adult -= 1;
      }

      if (type === "child") {
        if (isPlus && child < 10) child += 1;
        if (!isPlus && child > 0) child -= 1;
      }

      if (type === "room") {
        const minRoom = calculateMinRoom(adult, child);
        if (isPlus && room < 10) room += 1;
        if (!isPlus && room > minRoom) room -= 1;
      }

      updateGuestText();
    });
  });

  updateGuestText();

  if (typeof Swiper !== "undefined") {
    homeSwiper = new Swiper(".mySwiper", {
      slidesPerView: 3,
      spaceBetween: 30,
      loop: true,
      autoplay: {
        delay: 2500,
        disableOnInteraction: false,
        pauseOnMouseEnter: true
      },
      pagination: {
        el: ".swiper-pagination",
        clickable: true
      },
      navigation: {
        nextEl: ".swiper-button-next",
        prevEl: ".swiper-button-prev"
      },
      breakpoints: {
        0: {
          slidesPerView: 1
        },
        768: {
          slidesPerView: 2
        },
        1200: {
          slidesPerView: 3
        }
      }
    });
  }

  document.querySelectorAll(".star").forEach((star) => {
    star.addEventListener("click", function () {
      setSelectedRating(Number(this.getAttribute("data-value")));
    });
  });

  function setSelectedRating(rating) {
    selectedRating = rating;
    document.querySelectorAll(".star").forEach((item, index) => {
      item.classList.toggle("active", index < rating);
    });
  }

  function getTimestamp() {
    const now = new Date();
    return now.toLocaleString("id-ID", {
      hour: "2-digit",
      minute: "2-digit",
      day: "2-digit",
      month: "short",
      year: "numeric"
    });
  }

  function escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }

  function readComments() {
    try {
      const storedComments = localStorage.getItem(homeCommentsStorageKey);
      if (!storedComments) return [...defaultComments];

      const parsedComments = JSON.parse(storedComments);
      if (!Array.isArray(parsedComments) || parsedComments.length === 0) {
        return [...defaultComments];
      }

      return parsedComments.filter((comment) => {
        return comment && comment.name && comment.text && Number(comment.rating) > 0;
      });
    } catch (_error) {
      return [...defaultComments];
    }
  }

  function saveComments(comments) {
    localStorage.setItem(homeCommentsStorageKey, JSON.stringify(comments));
  }

  function buildCommentMarkup(comment) {
    const safeName = escapeHtml(comment.name);
    const safeText = escapeHtml(comment.text);
    const safeTime = escapeHtml(comment.time || getTimestamp());
    const starsDisplay = "&#9733;".repeat(Number(comment.rating) || 0);

    return `
      <div class="comment-item">
        <div class="comment-header d-flex justify-content-between align-items-start gap-3">
          <div>
            <span class="comment-username">@${safeName}</span>
            <div class="comment-rating">${starsDisplay}</div>
          </div>
          <span class="comment-time">${safeTime}</span>
        </div>
        <p class="comment-text">${safeText}</p>
      </div>
    `;
  }

  function renderComments() {
    const list = document.getElementById("commentList");
    if (!list) return;

    const comments = readComments();
    list.innerHTML = comments.map(buildCommentMarkup).join("");
  }

  renderComments();

  const addCommentBtn = document.getElementById("addCommentBtn");
  if (addCommentBtn) {
    addCommentBtn.addEventListener("click", () => {
      const nameInput = document.getElementById("commentName");
      const textInput = document.getElementById("commentText");
      const list = document.getElementById("commentList");

      const name = nameInput.value.trim();
      const text = textInput.value.trim();

      if (name === "" || text === "" || selectedRating === 0) {
        alert("Isi username, rating, dan ulasan!");
        return;
      }

      const comments = readComments();
      comments.unshift({
        name,
        text,
        rating: selectedRating,
        time: getTimestamp()
      });
      saveComments(comments);
      renderComments();

      nameInput.value = "";
      textInput.value = "";
      if (list) list.scrollTop = 0;
      setSelectedRating(0);
    });
  }
}

function destroyHomePage() {
  const root = document.querySelector(".hero-section");
  if (root) root.dataset.homeInitialized = "false";

  if (homeSwiper && typeof homeSwiper.destroy === "function") {
    homeSwiper.destroy(true, true);
    homeSwiper = null;
  }

  if (homeFlatpickr && typeof homeFlatpickr.destroy === "function") {
    homeFlatpickr.destroy();
    homeFlatpickr = null;
  }
}

document.addEventListener("turbo:load", initHomePage);
document.addEventListener("turbo:before-cache", destroyHomePage);
document.addEventListener("DOMContentLoaded", initHomePage);
